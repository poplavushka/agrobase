from markupsafe import Markup, escape
from sqlalchemy import String, cast, func, or_
from sqlalchemy.orm import undefer

from clld.db.meta import DBSession
from clld.db.models import common
from clld.web.datatables.base import (
    DISPLAY_LENGTH,
    DISPLAY_LIMIT,
    Col,
    DataTable,
    DetailsRowLinkCol,
    LinkCol,
)
from clld.web.datatables.language import IdCol, Languages as _Languages
from clld.web.datatables.source import Sources as _Sources, TypeCol
from clld.web.datatables.value import RefsCol, ValueNameCol, Values as _Values
from clld.web.util.helpers import link
from clld.web.util.htmllib import HTML

from agrobase import models


def _coerce_int(value, default):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _genetic_expr():
    bind = DBSession.get_bind()
    dialect = getattr(getattr(bind, 'dialect', None), 'name', None)
    if dialect == 'postgresql':
        return common.Language.jsondata['genetic'].astext
    return func.json_extract(cast(common.Language.jsondata, String), '$.genetic')


class GeneticCol(Col):
    """
    Колонка с семейной / генетической информацией из language.jsondata["genetic"].
    """

    def __init__(self, dt, name='genetic', **kw):
        kw.setdefault('sTitle', 'Genetic')
        super().__init__(dt, name, **kw)

    def format(self, lang):
        return (lang.jsondata or {}).get('genetic', '')

    def search(self, qs):
        needle = f"%{(qs or '').lower()}%"
        return func.lower(func.coalesce(_genetic_expr(), '')).like(needle)

    def order(self):
        # Вторичная сортировка по имени полезна, когда много языков в одной семье.
        return [_genetic_expr(), common.Language.name]


class SourcesCol(Col):
    __constraints__ = [common.Language]

    def __init__(self, dt, name='sources'):
        Col.__init__(
            self,
            dt,
            name,
            sTitle='Sources',
            bSortable=False,
            bSearchable=False,
        )

    def format(self, item):
        """Список источников типа 'Corbett 2010', 'Van Urk 2015' и т.п."""
        seen = set()
        parts = []

        for vs in item.valuesets:
            for ref in vs.references:
                src = ref.source
                if not src or src.id in seen:
                    continue
                seen.add(src.id)
                parts.append(link(self.dt.req, src, label=src.name))

        return ', '.join(parts)


class LanguagesDataTable(_Languages):
    """Переопределяем стандартную таблицу языков."""

    def col_defs(self):
        return [
            PartialIdCol(self, 'id', model_col=common.Language.id, sTitle='Id'),
            LinkCol(self, 'name', model_col=common.Language.name, sTitle='Name'),
            GeneticCol(self),
            SourcesCol(self),
        ]

    def base_query(self, query):
        return query.order_by(common.Language.name)

    def get_query(self, limit=DISPLAY_LENGTH, offset=0, undefer_cols=()):
        query = self.base_query(
            DBSession.query(self.db_model()).filter(self.db_model().active == True)
        )
        self.count_all = query.count()

        # Пер-колоночные фильтры (стандартный протокол DataTables 1.x).
        column_filters = []
        for name, val in self.req.params.items():
            if not (val and name.startswith('sSearch_')):
                continue
            colindex = _coerce_int(name.split('_')[1], -1)
            if not (0 <= colindex < len(self.cols)):
                continue
            clauses = self.cols[colindex].search(val)
            if clauses is None:
                continue
            if not isinstance(clauses, (tuple, list)):
                clauses = [clauses]
            for clause in clauses:
                if clause is None:
                    continue
                query = query.filter(clause)
                column_filters.append((colindex, self.cols[colindex].js_args['sTitle'], val))

        for colindex, coltitle, qs in sorted(set(column_filters)):
            self.filters.append((coltitle, qs))

        # Глобальный поиск из поля Search.
        search_term = (self.req.params.get('sSearch') or '').strip()
        if search_term:
            clauses = []
            for col in self.cols:
                if not col.js_args.get('bSearchable', True):
                    continue
                q = col.search(search_term)
                if q is None:
                    continue
                if not isinstance(q, (tuple, list)):
                    q = [q]
                clauses.extend([c for c in q if c is not None])
            if clauses:
                query = query.filter(or_(*clauses))
                self.filters.append(('Search', search_term))

        self.count_filtered = query.count()

        i_sorting_cols = min(_coerce_int(self.req.params.get('iSortingCols'), 0), 10)
        for index in range(i_sorting_cols):
            sort_col = _coerce_int(self.req.params.get(f'iSortCol_{index}'), -1)
            if not (0 <= sort_col < len(self.cols)):
                continue
            col = self.cols[sort_col]
            if not col.js_args.get('bSortable', True):
                continue
            orders = col.order()
            if orders is None:
                continue
            if not isinstance(orders, (tuple, list)):
                orders = [orders]
            for order in orders:
                if self.req.params.get(f'sSortDir_{index}') == 'desc':
                    order = order.desc()
                query = query.order_by(order)

        default_orders = self.default_order()
        if not isinstance(default_orders, (tuple, list)):
            default_orders = (default_orders,)
        query = query.order_by(*default_orders)

        if 'iDisplayLength' in self.req.params:
            limit = _coerce_int(self.req.params.get('iDisplayLength'), DISPLAY_LENGTH)
            limit = min(limit, DISPLAY_LIMIT)

        query = query.limit(DISPLAY_LIMIT if limit == -1 else limit).offset(
            _coerce_int(self.req.params.get('iDisplayStart'), offset)
        )

        if undefer_cols:
            query = query.options(*(undefer(c) for c in undefer_cols))

        return query


class FullDetailsRowLinkCol(DetailsRowLinkCol):
    __kw__ = dict(DetailsRowLinkCol.__kw__, button_text='full')


class PartialIdCol(IdCol):
    """ID search by substring instead of exact match."""

    def format(self, item):
        glottocode = (item.jsondata or {}).get('glottocode')
        if not glottocode:
            return escape(item.id)
        return Markup(
            '<a href="https://glottolog.org/resource/languoid/id/{code}" '
            'target="_blank" rel="noopener">{label}</a>'.format(
                code=escape(glottocode),
                label=escape(item.id),
            )
        )

    def search(self, qs):
        needle = f"%{(qs or '').strip()}%"
        return self.model_col.ilike(needle)


class SourcesDataTable(_Sources):
    def col_defs(self):
        return [
            FullDetailsRowLinkCol(self, 'd'),
            LinkCol(self, 'name'),
            Col(self, 'description', sTitle='Title', format=lambda i: HTML.span(i.description)),
            Col(self, 'year'),
            Col(self, 'author'),
            TypeCol(self, 'bibtex_type'),
        ]


class ExampleCol(Col):
    def __init__(self, dt, name='example'):
        super().__init__(
            dt,
            name,
            sTitle='Example',
            bSortable=False,
            bSearchable=False,
            sClass='example-col',
        )

    @staticmethod
    def _strip_outer_quotes(text):
        if text is None:
            return ''
        text = str(text).strip()
        if not text:
            return ''
        pairs = {'"': '"', "'": "'", '«': '»', '“': '”', '„': '“', '‘': '’'}
        if len(text) >= 2 and text[0] in pairs and text[-1] == pairs[text[0]]:
            return text[1:-1].strip()
        return text

    def format(self, item):
        sentence = self.dt.examples_by_param_pk.get(item.valueset.parameter_pk)
        if sentence is None:
            return ''

        primary = self._strip_outer_quotes(sentence.name or '')
        gloss = self._strip_outer_quotes(getattr(sentence, 'gloss', '') or '')
        translation = self._strip_outer_quotes(sentence.description or '')

        parts = []
        if primary:
            parts.append(f'<div class="example-line">{escape(primary)}</div>')
        if gloss:
            parts.append(f'<div class="example-line">{escape(gloss)}</div>')
        if translation:
            parts.append(
                f'<div class="example-translation">&#8216;{escape(translation)}&#8217;</div>'
            )
        return Markup(''.join(parts))


class ParameterExampleLinkCol(Col):
    def __init__(self, dt, name='example'):
        super().__init__(
            dt,
            name,
            sTitle='Example',
            bSortable=False,
            bSearchable=False,
            sClass='center',
        )

    def format(self, item):
        language = item.valueset.language
        if not language:
            return 'no examples'

        sentence = self.dt.examples_by_language_pk.get(language.pk)
        if sentence is None:
            return 'no examples'

        return Markup(
            '<button type="button" class="btn-info value-example" '
            'data-lang-id="{lang_id}" data-lang-name="{lang_name}" '
            'data-param-id="{param_id}">show</button>'.format(
                lang_id=escape(language.id),
                lang_name=escape(language.name),
                param_id=escape(item.valueset.parameter.id),
            )
        )


class ParameterDisplayValueCol(ValueNameCol):
    def __init__(self, dt, name='value'):
        super().__init__(dt, name, sClass='parameter-value-col')

    def format(self, item):
        label = str(item).strip()
        label_lower = label.lower()

        if label_lower == 'yes':
            return Markup('<span class="parameter-binary-value value-yes">+</span>')
        if label_lower == 'no':
            return Markup('<span class="parameter-binary-value value-no">-</span>')

        return Markup('<span class="parameter-plain-value">{}</span>'.format(escape(label)))


class ValuesDataTable(_Values):
    def __init__(self, req, model, **kw):
        super().__init__(req, model, **kw)
        self.examples_by_param_pk = {}
        self.examples_by_language_pk = {}

        if self.language:
            rows = (
                DBSession.query(models.SentenceParameter.parameter_pk, common.Sentence)
                .join(common.Sentence, models.SentenceParameter.sentence_pk == common.Sentence.pk)
                .filter(common.Sentence.language_pk == self.language.pk)
                .order_by(common.Sentence.pk)
                .all()
            )
            for param_pk, sentence in rows:
                self.examples_by_param_pk.setdefault(param_pk, sentence)

        if self.parameter:
            rows = (
                DBSession.query(common.Sentence.language_pk, common.Sentence)
                .join(models.SentenceParameter, models.SentenceParameter.sentence_pk == common.Sentence.pk)
                .filter(models.SentenceParameter.parameter_pk == self.parameter.pk)
                .order_by(common.Sentence.pk)
                .all()
            )
            for language_pk, sentence in rows:
                self.examples_by_language_pk.setdefault(language_pk, sentence)

    def col_defs(self):
        if self.parameter:
            return [
                ParameterExampleLinkCol(self),
                LinkCol(
                    self,
                    'language',
                    model_col=common.Language.name,
                    get_object=lambda i: i.valueset.language,
                ),
                ParameterDisplayValueCol(self, 'value'),
                RefsCol(self, 'source'),
            ]

        if self.language:
            return [
                DetailsRowLinkCol(self, 'd'),
                ValueNameCol(self, 'value'),
                ExampleCol(self),
                LinkCol(
                    self,
                    'parameter',
                    sTitle=self.req.translate('Parameter'),
                    model_col=common.Parameter.name,
                    get_object=lambda i: i.valueset.parameter,
                ),
                RefsCol(self, 'source'),
            ]

        return super().col_defs()


class ParamValueCol(Col):
    """
    Колонка "значение параметра для языка":
    ищем ValueSet по (language, parameter),
    берём первое значение и показываем name / domainelement.name.
    """

    def __init__(self, dt, parameter, **kw):
        self.parameter = parameter
        kw.setdefault('sTitle', parameter.name)
        super().__init__(dt, parameter.id, **kw)

    def format(self, lang):
        vs = (
            DBSession.query(common.ValueSet)
            .filter(
                common.ValueSet.language_pk == lang.pk,
                common.ValueSet.parameter_pk == self.parameter.pk,
            )
            .first()
        )
        if not vs:
            return ''

        vals = []
        for v in vs.values:
            if v.domainelement:
                vals.append(v.domainelement.name)
            elif v.name:
                vals.append(v.name)

        return ', '.join(vals)


class AgreementLanguageTable(DataTable):
    """
    Таблица: строка = язык, колонки = Name, Genetic, затем metadata и agreement.
    Никакой широты/долготы.
    """

    def __init__(self, req, model, **kw):
        super().__init__(req, model, **kw)

        # по умолчанию (нет параметров) всё показываем
        show_meta_param = req.params.get('show_meta')
        self.show_meta = True if show_meta_param is None else (show_meta_param == '1')

        show_agr_param = req.params.get('show_agr')
        self.show_agr = True if show_agr_param is None else (show_agr_param == '1')

        # кешируем параметры по группам
        all_params = DBSession.query(common.Parameter).all()

        self.meta_params = [
            p for p in all_params
            if (p.jsondata or {}).get('group') == 'language-metadata'
        ]
        self.agr_params = [
            p for p in all_params
            if (p.jsondata or {}).get('group') == 'agreement'
        ]

    def col_defs(self):
        language = common.Language

        cols = [
            LinkCol(self, 'name', model_col=language.name),
            GeneticCol(self),
        ]

        if self.show_meta:
            for p in self.meta_params:
                cols.append(ParamValueCol(self, p))

        if self.show_agr:
            for p in self.agr_params:
                cols.append(ParamValueCol(self, p))

        return cols

    def base_query(self, query):
        return query.order_by(common.Language.name)

    def xhr_query(self):
        """
        Протаскиваем show_meta/show_agr в AJAX-запрос, чтобы HTML и JSON-рендеры
        совпадали по набору колонок (иначе DataTables ругается).
        """
        q = super().xhr_query()
        q['show_meta'] = '1' if self.show_meta else '0'
        q['show_agr'] = '1' if self.show_agr else '0'
        return q


def includeme(config):
    config.register_datatable('languages', LanguagesDataTable)
    config.register_datatable('sources', SourcesDataTable)
    config.register_datatable('values', ValuesDataTable)
