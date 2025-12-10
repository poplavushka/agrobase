from pyramid.view import view_config
from pyramid.httpexceptions import HTTPNotFound
from clld.db.meta import DBSession
from clld.db.models import common
from agrobase import models


@view_config(route_name='param_groups', renderer='param_groups.mako')
def param_groups(req):
    groups = [
        dict(id='language-metadata', name='Language metadata'),
        dict(id='agreement', name='Agreement'),
    ]
    return dict(groups=groups, request=req)


@view_config(route_name='param_group', renderer='param_group.mako')
def param_group(req):
    group_id = req.matchdict['group']  # 'language-metadata' или 'agreement'

    all_params = DBSession.query(common.Parameter).all()
    params_in_group = [
        p for p in all_params
        if (p.jsondata or {}).get('group') == group_id
    ]

    if group_id == 'agreement':
        # На втором уровне показываем только гиперпараметры
        params = [
            p for p in params_in_group
            if not (p.jsondata or {}).get('parent')
        ]
    else:
        params = params_in_group

    return dict(group_id=group_id, params=params, request=req)


@view_config(route_name='param_hyper', renderer='param_hyper.mako')
def param_hyper(req):
    group_id = req.matchdict['group']      # 'agreement'
    parent_id = req.matchdict['parent']    # 'pred_agreement'

    hyperparam = (
        DBSession.query(common.Parameter)
        .filter_by(id=parent_id)
        .first()
    )
    if hyperparam is None:
        raise HTTPNotFound()

    all_params = DBSession.query(common.Parameter).all()
    child_params = [
        p for p in all_params
        if (p.jsondata or {}).get('group') == group_id
        and (p.jsondata or {}).get('parent') == parent_id
    ]

    return dict(
        group_id=group_id,
        hyperparam=hyperparam,
        params=child_params,
        request=req,
    )


# --------  Agreement + metadata table (БЕЗ clld-datatables)  --------

@view_config(route_name='agreement_table', renderer='agreement_table.mako')
def agreement_table_view(req):
    """
    Agreement & metadata table:
      - одна HTML-таблица (без clld-datatables),
      - DataTables по DOM,
      - иерархические фильтры для agreement-фич.
    """
    # какие группы признаков показывать как колонки
    show_meta = (req.params.get('show_meta', '1') == '1')
    show_agr = (req.params.get('show_agr', '1') == '1')

    # языки
    languages = (
        DBSession.query(common.Language)
        .order_by(common.Language.name)
        .all()
    )

    # параметры в стабильном порядке (по pk ~ по CSV)
    all_params = (
        DBSession.query(common.Parameter)
        .order_by(common.Parameter.pk)
        .all()
    )

    # metadata-параметры
    meta_params = [
        p for p in all_params
        if (p.jsondata or {}).get('group') == 'language-metadata'
    ]

    # все agreement-параметры
    agr_params_all = [
        p for p in all_params
        if (p.jsondata or {}).get('group') == 'agreement'
    ]

    # гиперпараметры (без parent) и дочерние (parent = id гиперпараметра)
    agr_hyperparams = [
        p for p in agr_params_all
        if not (p.jsondata or {}).get('parent')
    ]
    agr_children_map = {}
    for hp in agr_hyperparams:
        agr_children_map[hp.id] = [
            p for p in agr_params_all
            if (p.jsondata or {}).get('parent') == hp.id
        ]

    # в колонках таблицы всё равно показываем ВСЕ agreement-параметры
    agr_params = agr_params_all

    # значения признаков: (lang_pk, param_pk) -> строка
    value_map = {}
    relevant_params = []
    if show_meta:
        relevant_params.extend(meta_params)
    if show_agr:
        relevant_params.extend(agr_params)
    relevant_pks = {p.pk for p in relevant_params}

    if languages and relevant_pks:
        lang_pks = [l.pk for l in languages]
        vs_list = (
            DBSession.query(common.ValueSet)
            .filter(common.ValueSet.language_pk.in_(lang_pks))
            .filter(common.ValueSet.parameter_pk.in_(relevant_pks))
            .all()
        )
        for vs in vs_list:
            vals = []
            for v in vs.values:
                if v.domainelement:
                    vals.append(v.domainelement.name)
                elif v.name:
                    vals.append(v.name)
            value_map[(vs.language_pk, vs.parameter_pk)] = ', '.join(vals)

    # сопоставление параметр -> индекс колонки в таблице
    # 0: Language, 1: Genetic, дальше параметры
    col_index_by_pk = {}
    col_idx = 2
    if show_meta:
        for p in meta_params:
            col_index_by_pk[p.pk] = col_idx
            col_idx += 1
    if show_agr:
        for p in agr_params:
            col_index_by_pk[p.pk] = col_idx
            col_idx += 1

    return dict(
        request=req,
        languages=languages,
        meta_params=meta_params,
        agr_params=agr_params,
        agr_hyperparams=agr_hyperparams,
        agr_children_map=agr_children_map,
        col_index_by_pk=col_index_by_pk,
        show_meta=show_meta,
        show_agr=show_agr,
        value_map=value_map,
    )

@view_config(route_name='feature_examples', renderer='json')
def feature_examples(req):
    """
    AJAX-view: вернуть примеры для пары (язык, параметр).
    Используется, когда пользователь кликает по ячейке таблицы.
    """
    lang_id = req.params.get('lang')
    param_id = req.params.get('param')

    if not lang_id or not param_id:
        return {'ok': False, 'error': 'Missing lang or param'}

    lang = DBSession.query(common.Language).filter_by(id=lang_id).first()
    param = DBSession.query(common.Parameter).filter_by(id=param_id).first()

    if not lang or not param:
        return {'ok': False, 'error': 'Unknown language or parameter'}

    # Ищем предложения, привязанные к этому параметру и к этому языку.
    sents = (
        DBSession.query(common.Sentence)
        .join(models.SentenceParameter)
        .filter(
            models.SentenceParameter.parameter_pk == param.pk,
            common.Sentence.language_pk == lang.pk,
        )
        .order_by(common.Sentence.pk)
        .limit(20)
        .all()
    )

    examples = []
    for s in sents:
        examples.append({
            'id': s.id,
            'primary': s.name or '',
            'gloss': getattr(s, 'gloss', '') or '',
            'translation': s.description or '',
            'url': req.resource_url(s),
        })

    return {
        'ok': True,
        'language': {'id': lang.id, 'name': lang.name},
        'parameter': {'id': param.id, 'name': param.name},
        'examples': examples,
    }

@view_config(route_name='feature_combinations',
             renderer='feature_combinations.mako')
def feature_combinations_view(req):
    """
    Страница 'Combination of features':
    - форма с выбором до 3 кодов (DomainElement.id),
    - языки, удовлетворяющие всем выбранным кодам,
    - карта + простая таблица.
    """

    # Параметры, которые вообще имеют коды (DomainElement)
    params = (
        DBSession.query(common.Parameter)
        .join(common.DomainElement)
        .distinct()
        .order_by(common.Parameter.name)
        .all()
    )

    # выбранные коды c1, c2, c3
    selected_codes = []
    for i in range(1, 4):
        cid = req.params.get(f'c{i}') or ''
        selected_codes.append(cid)

    active_codes = [c for c in selected_codes if c]

    languages = []
    if active_codes:
        all_langs = DBSession.query(common.Language).all()
        for lang in all_langs:
            ok = True
            for cid in active_codes:
                exists = (
                    DBSession.query(common.Value)
                    .join(common.ValueSet)
                    .join(common.DomainElement)
                    .filter(
                        common.ValueSet.language_pk == lang.pk,
                        common.DomainElement.id == cid,
                    )
                    .first()
                )
                if not exists:
                    ok = False
                    break
            if ok:
                languages.append(lang)

    map_ = None
    if languages:
        # карта зарегистрирована в agrobase.maps как 'feature_combination'
        map_ = req.get_map('feature_combination', languages=languages)

    return dict(
        request=req,
        params=params,
        selected_codes=selected_codes,
        active_codes=active_codes,
        languages=languages,
        map_=map_,
    )


