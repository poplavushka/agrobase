import collections

from pyramid.config import Configurator
from clld.interfaces import IMapMarker, IValueSet, IValue, IDomainElement
from clld.web.icon import MapMarker
from clldutils.svg import pie, icon, data_url

from agrobase import models


def main(global_config, **settings):
    config = Configurator(settings=settings)

    # базовое приложение clld и наши модули
    config.include('clld.web.app')
    config.include('agrobase.models')
    config.include('agrobase.adapters')
    config.include('agrobase.datatables')
    config.include('agrobase.maps')

    # статика проекта (сюда попадает project.css)
    config.add_static_view('agrobase', 'agrobase:static', cache_max_age=3600)

    # наши дополнительные маршруты
    config.add_route('param_groups', '/param-groups')
    config.add_route('param_group', '/param-groups/{group}')
    config.add_route('param_hyper', '/param-groups/{group}/{parent}')

    config.add_route('agreement_table', '/agreement-table')
    config.add_route('feature_combinations', '/feature-combinations')
    config.add_route('feature_examples', '/feature-examples')

    # главное меню в шапке
    config.register_menu(
        ('home', lambda ctx, req: (req.route_url('dataset'), 'Home')),
        ('agreement_table', lambda ctx, req: (
            req.route_url('agreement_table'), 'Features'
        )),
        ('parameters', lambda ctx, req: (req.route_url('parameters'), 'Parameters')),
        ('languages', lambda ctx, req: (req.route_url('languages'), 'Languages')),
        ('sources', lambda ctx, req: (req.route_url('sources'), 'Sources')),

        
        #('feature_combinations', lambda ctx, req: (
        #    req.route_url('feature_combinations'), 'Features map'
        #)),

        ('feedback', lambda ctx, req: (
            'https://docs.google.com/forms/d/e/1FAIpQLSftKiyTOWGrU0nksOCpqdvbv7SoW_11VQUe8OPMk-NVVEQpsw/viewform?usp=header',
            'Feedback'
        )),

       # ('legal', lambda ctx, req: (req.route_url('legal'), 'Legal')),
        #('download', lambda ctx, req: (req.route_url('download'), 'Download')),
       # ('contact', lambda ctx, req: (req.route_url('contact'), 'Contact')),
    )

    config.scan()
    return config.make_wsgi_app()
