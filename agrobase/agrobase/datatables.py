from clld.web.datatables.base import DataTable, Col, LinkCol
from clld.db.meta import DBSession
from clld.db.models import common
from clld.web.datatables.language import Languages as _Languages
from clld.web.datatables.parameter import Parameters as _Parameters
from clld.web.util.helpers import link
from markupsafe import Markup, escape
from sqlalchemy import func, or_
from agrobase import models

# --- ВАЖНО: импорт стандартного Values ---
try:
    from clld.web.datatables.value import Values as _Values
except Exception:
    _Values = DataTable


# -------------------- helpers --------------------

def _get_family(lang):
    jd = lang.jsondata or {}
    return ((jd.get('genetic_family') or jd.get('genetic') or '')).strip()


def _get_branch(lang):
    jd = lang.jsondata or {}
    return ((jd.get('genetic_branch') or '')).strip()


def _get_lat_lon(lang):
    lat = getattr(lang, 'latitude', None)
    lon = getattr(lang, 'longitude', None)
    jd = lang.jsondata or {}
    if lat in (None, ''):
        lat = jd.get('latitude') or jd.get('Latitude') or ''
    if lon in (None, ''):
        lon = jd.get('longitude') or jd.get('Longitude') or ''
    return lat, lon


def _value_label(v):
    if getattr(v, 'domainelement', None):
        return (v.domainelement.name or '').strip()
    return (v.name or '').strip()


def _is_binary_yesno_parameter(param):
    """Даже если домена нет — попробуем понять по данным в БД."""
    if not param:
        return False

    dom = getattr(param, 'domain', None)
    if dom:
        vals = {(de.name or '').strip().lower() for de in dom if (de.name or '').strip()}
        if vals and vals.issubset({'yes', 'no'}):
            return True

    # fallback по данным
    vals = {
        (hint or '').strip().lower()
        for (hint,) in (
            DBSession.query(
                func.lower(func.coalesce(common.DomainElement.name, common.Value.name))
            )
            .join(common.Value.valueset)
            .outerjoin(common.Value.domainelement)
            .filter(common.ValueSet.parameter_pk == param.pk)
            .distinct()
            .all()
        )
    }
    vals = {v for v in vals if v}
    return bool(vals) and vals.issubset({'yes', 'no'})


# -------------------- Parameters list --------------------


class ParametersDataTable(_Parameters):
    def col_defs(self):
        P = common.Parameter
        return [
            LinkCol(self, 'name', model_col=P.name, sTitle='Feature', sClass='agro-param-name'),
            Col(
                self, 'author_json', sTitle='Author', model_col=None,
                format=lambda p: (
                    (p.jsondata or {}).get('author')
                    or (p.jsondata or {}).get('compiled')
                    or (p.jsondata or {}).get('compiled_by')
                    or ''
                ).strip()
            ),
        ]

    def base_query(self, query):
        return query.order_by(common.Parameter.name)


# -------------------- Parameter detail: custom values table --------------------

class PvLanguageCol(Col):
    def __init__(self, dt, name='language', **kw):
        kw.setdefault('sTitle', 'Language')
        super().__init__(dt, name, **kw)

    def format(self, v):
        lang = v.valueset.language
        return link(self.dt.req, lang, label=lang.name)


class PvFamilyCol(Col):
    def __init__(self, dt, name='family', **kw):
        kw.setdefault('sTitle', 'Family')
        super().__init__(dt, name, **kw)

    def format(self, v):
        return _get_family(v.valueset.language)


class PvBranchCol(Col):
    def __init__(self, dt, name='branch', **kw):
        kw.setdefault('sTitle', 'Branch')
        super().__init__(dt, name, **kw)

    def format(self, v):
        return _get_branch(v.valueset.language)


class PvValueCol(Col):
    def __init__(self, dt, name='value', **kw):
        kw.setdefault('sTitle', 'Value')
        super().__init__(dt, name, **kw)

    def format(self, v):
        return _value_label(v)


class PvExampleCol(Col):
    def __init__(self, dt, name='example', **kw):
        kw.setdefault('sTitle', 'Example')
        kw.setdefault('bSortable', False)
        kw.setdefault('bSearchable', False)
        super().__init__(dt, name, **kw)

    def format(self, v):
        lang = v.valueset.language
        param = getattr(self.dt, 'agro_parameter', None)
        if not param:
            return ''

        # проверяем, есть ли хотя бы 1 пример
        exists = (
            DBSession.query(common.Sentence.pk)
            .join(models.SentenceParameter)
            .filter(common.Sentence.language_pk == lang.pk)
            .filter(models.SentenceParameter.parameter_pk == param.pk)
            .first()
        )
        if not exists:
            return ''

        return Markup(
            '<a href="#" class="value-example" '
            f'data-lang-id="{escape(lang.id)}" '
            f'data-lang-name="{escape(lang.name)}" '
            f'data-param-id="{escape(param.id)}">more</a>'
        )


class PvShowOnMapCol(Col):
    def __init__(self, dt, name='show_on_map', **kw):
        kw.setdefault('sTitle', 'Show on the map')
        kw.setdefault('bSortable', False)
        kw.setdefault('bSearchable', False)
        super().__init__(dt, name, **kw)

    def format(self, v):
        lang = v.valueset.language
        lat, lon = _get_lat_lon(lang)
        if lat in (None, '') or lon in (None, ''):
            return ''

        svg = (
            '<svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true" '
            'style="vertical-align:-2px;">'
            '<path fill="currentColor" d="M12 2c-3.86 0-7 3.14-7 7c0 5.25 7 13 7 13s7-7.75 7-13c0-3.86-3.14-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5z"/>'
            '</svg>'
        )
        return Markup(
            '<a href="#" class="show-on-map btn btn-mini" title="Show on the map" '
            f'data-lang-id="{escape(lang.id)}" '
            f'data-lang-name="{escape(lang.name)}" '
            f'data-lat="{escape(str(lat))}" data-lon="{escape(str(lon))}">'
            f'{svg}</a>'
        )

class LvParameterCol(Col):
    def __init__(self, dt, name='parameter', **kw):
        kw.setdefault('sTitle', 'Parameter')
        kw.setdefault('sWidth', '240px')
        super().__init__(dt, name, **kw)

    def format(self, v):
        param = v.valueset.parameter
        return link(self.dt.req, param, label=param.name)


class LvValueCol(Col):
    def __init__(self, dt, name='value', **kw):
        kw.setdefault('sTitle', 'Value')
        kw.setdefault('sWidth', '80px')
        super().__init__(dt, name, **kw)

    def format(self, v):
        # показываем ВСЕ значения valueset (если вдруг их несколько)
        vals = []
        for vv in v.valueset.values:
            lab = _value_label(vv)
            if lab:
                vals.append(lab)
        return ', '.join(vals)


class LvExampleCol(Col):
    def __init__(self, dt, name='example', **kw):
        kw.setdefault('sTitle', 'Example')
        kw.setdefault('bSortable', False)
        kw.setdefault('bSearchable', True)
        kw.setdefault('sClass', 'agro-col-example')
        super().__init__(dt, name, **kw)

    def format(self, v):
        lang = v.valueset.language
        param = v.valueset.parameter

        ex = (
            DBSession.query(common.Sentence)
            .join(models.SentenceParameter)
            .filter(
                common.Sentence.language_pk == lang.pk,
                models.SentenceParameter.parameter_pk == param.pk,
            )
            .order_by(common.Sentence.pk)
            .first()
        )
        if not ex:
            return ''

        primary = (ex.name or '').strip()
        gloss = (getattr(ex, 'gloss', '') or '').strip()
        trans = (ex.description or '').strip()

        parts = ['<div class="agro-example">']
        if primary:
            parts.append(f'<pre class="agro-ex-line">{escape(primary)}</pre>')
        if gloss:
            parts.append(f'<pre class="agro-ex-line agro-gloss">{escape(gloss)}</pre>')
        if trans:
            parts.append(f'<div class="agro-translation">&#8216;{escape(trans)}&#8217;</div>')
        parts.append('</div>')
        return Markup(''.join(parts))


class LvSourceCol(Col):
    def __init__(self, dt, name='source', **kw):
        kw.setdefault('sTitle', 'Source')
        kw.setdefault('sWidth', '200px')
        kw.setdefault('bSortable', False)
        kw.setdefault('sClass', 'agro-col-source')
        super().__init__(dt, name, **kw)

    def format(self, v):
        # источники именно для этого valueset
        seen = set()
        items = []
        for ref in getattr(v.valueset, 'references', []) or []:
            src = ref.source
            if not src or src.pk in seen:
                continue
            seen.add(src.pk)
            items.append(link(self.dt.req, src, label=src.name))

        return Markup(', ').join(items) if items else ''


class ValuesDataTable(_Values):
    def __init__(self, req, model, **kw):
        self.agro_parameter = kw.pop('parameter', None) or kw.pop('agro_parameter', None)
        self.agro_language  = kw.pop('language', None)  or kw.pop('agro_language', None)

        # --- XHR: берём id из query string ---
        if self.agro_parameter is None:
            pid = req.params.get('parameter_id')
            if pid:
                self.agro_parameter = (
                    DBSession.query(common.Parameter)
                    .filter(common.Parameter.id == pid)
                    .first()
                )

        if self.agro_language is None:
            lid = req.params.get('language_id')
            if lid:
                self.agro_language = (
                    DBSession.query(common.Language)
                    .filter(common.Language.id == lid)
                    .first()
                )

        # --- fallback: если это НЕ XHR, можно понять по route ---
        mr = getattr(req, 'matched_route', None)
        md = getattr(req, 'matchdict', {}) or {}
        if self.agro_parameter is None and mr and mr.name == 'parameter':
            pid = md.get('id')
            if pid:
                self.agro_parameter = (
                    DBSession.query(common.Parameter)
                    .filter(common.Parameter.id == pid)
                    .first()
                )
        if self.agro_language is None and mr and mr.name == 'language':
            lid = md.get('id')
            if lid:
                self.agro_language = (
                    DBSession.query(common.Language)
                    .filter(common.Language.id == lid)
                    .first()
                )

        super().__init__(req, model, **kw)
        self.is_yesno = _is_binary_yesno_parameter(self.agro_parameter) if self.agro_parameter else False


    @property
    def mode(self):
        if self.agro_parameter is not None:
            return 'parameter'
        if self.agro_language is not None:
            return 'language'
        return None

    def col_defs(self):
        if self.mode == 'parameter':
            cols = [PvLanguageCol(self), PvFamilyCol(self), PvBranchCol(self)]
            if not self.is_yesno:
                cols.append(PvValueCol(self))
            cols.extend([PvExampleCol(self), PvShowOnMapCol(self)])
            return cols

        if self.mode == 'language':
            return [LvParameterCol(self), LvValueCol(self), LvExampleCol(self), LvSourceCol(self)]

        return super().col_defs()

    def base_query(self, query):
        if self.mode == 'parameter':
            base = (
                query
                .join(common.Value.valueset)
                .join(common.ValueSet.language)
                .outerjoin(common.Value.domainelement)
                .filter(common.ValueSet.parameter_pk == self.agro_parameter.pk)
            )

            if self.is_yesno:
                base = base.filter(
                    or_(
                        func.lower(common.Value.name) == 'yes',
                        func.lower(common.DomainElement.name) == 'yes',
                    )
                )

            # 1 строка на язык
            subq = (
                base.with_entities(func.min(common.Value.pk).label('pk'))
                .group_by(common.ValueSet.language_pk)
                .subquery()
            )

            return (
                query.session.query(common.Value)
                .filter(common.Value.pk.in_(subq))
                .join(common.Value.valueset)
                .join(common.ValueSet.language)
                .outerjoin(common.Value.domainelement)
                .order_by(common.Language.name)
            )

        if self.mode == 'language':
            base = (
                query
                .join(common.Value.valueset)
                .join(common.ValueSet.parameter)
                .outerjoin(common.Value.domainelement)
                .filter(common.ValueSet.language_pk == self.agro_language.pk)
            )

            # 1 строка на параметр
            subq = (
                base.with_entities(func.min(common.Value.pk).label('pk'))
                .group_by(common.ValueSet.parameter_pk)
                .subquery()
            )

            return (
                query.session.query(common.Value)
                .filter(common.Value.pk.in_(subq))
                .join(common.Value.valueset)
                .join(common.ValueSet.parameter)
                .outerjoin(common.Value.domainelement)
                .order_by(common.Parameter.name)
            )

        return super().base_query(query)

    def xhr_query(self):
        q = super().xhr_query()
        if self.mode == 'parameter' and self.agro_parameter:
            q['parameter_id'] = self.agro_parameter.id
        if self.mode == 'language' and self.agro_language:
            q['language_id'] = self.agro_language.id
        return q




# -------------------- Languages --------------------

class LanguagesDataTable(_Languages):
    def col_defs(self):
        return [
            LinkCol(self, 'name', model_col=common.Language.name, sTitle='Language'),

            # ВАЖНО: НЕ 'glottocode', иначе clld подхватит Language.glottocode (property) и упадёт
            Col(
                self, 'glottocode_json', sTitle='Glottocode', model_col=None,
                format=self.format_glottocode
            ),

            Col(self, 'family', sTitle='Family', model_col=None,
                format=lambda lang: _get_family(lang)),
            Col(self, 'branch', sTitle='Branch', model_col=None,
                format=lambda lang: _get_branch(lang)),

            Col(self, 'sources', sTitle='Sources', model_col=None,
                bSortable=False, format=self.render_sources),
        ]

    def format_glottocode(self, lang):
        gc = ((lang.jsondata or {}).get('glottocode') or '').strip()
        if not gc:
            return ''
        url = f'https://glottolog.org/resource/languoid/id/{escape(gc)}'
        return Markup(
            f'<a href="{url}" target="_blank" rel="noopener">{escape(gc)}</a>'
        )

    def render_sources(self, lang):
        # Тут именно ссылки на Source (литературу), а не цифры
        src_pks = set()

        for (pk,) in (
            DBSession.query(common.ValueSetReference.source_pk)
            .join(common.ValueSet, common.ValueSet.pk == common.ValueSetReference.valueset_pk)
            .filter(common.ValueSet.language_pk == lang.pk)
            .distinct()
            .all()
        ):
            if pk:
                src_pks.add(pk)

        for (pk,) in (
            DBSession.query(common.SentenceReference.source_pk)
            .join(common.Sentence, common.Sentence.pk == common.SentenceReference.sentence_pk)
            .filter(common.Sentence.language_pk == lang.pk)
            .distinct()
            .all()
        ):
            if pk:
                src_pks.add(pk)

        if not src_pks:
            return ''

        sources = (
            DBSession.query(common.Source)
            .filter(common.Source.pk.in_(src_pks))
            .order_by(common.Source.name)
            .all()
        )

        max_show = 3
        shown = sources[:max_show]
        hidden_n = max(0, len(sources) - len(shown))

        links_html = Markup(', ').join([link(self.req, s, label=s.name) for s in shown])
        full_title = '; '.join([s.name for s in sources]).strip()

        if hidden_n:
            return Markup(
                f'<span title="{escape(full_title)}">'
                f'{links_html} <span class="muted">+{hidden_n} more</span>'
                f'</span>'
            )

        return Markup(f'<span title="{escape(full_title)}">{links_html}</span>')


def includeme(config):
    config.register_datatable('parameters', ParametersDataTable)
    config.register_datatable('languages', LanguagesDataTable)
    # ПЕРЕОПРЕДЕЛЯЕМ values (то, что рендерится на parameter detail)
    config.register_datatable('values', ValuesDataTable)
