from clld.web.datatables.base import DataTable, Col, LinkCol
from clld.db.meta import DBSession
from clld.db.models import common


class GeneticCol(Col):
    """
    Колонка с семейной / генетической информацией из language.jsondata["genetic"].
    """
    def __init__(self, dt, name='genetic', **kw):
        kw.setdefault('sTitle', 'Genetic')
        super().__init__(dt, name, **kw)

    def format(self, lang):
        return (lang.jsondata or {}).get('genetic', '')


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

        # если хочешь контроль над порядком — сортируй здесь
        # self.meta_params.sort(key=lambda p: p.id)
        # self.agr_params.sort(key=lambda p: p.id)

    def col_defs(self):
        Language = common.Language

        cols = [
            LinkCol(self, 'name', model_col=Language.name),
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
    config.register_datatable('agreement_table', AgreementLanguageTable)
