import collections

from pyramid.config import Configurator
from clld.interfaces import IMapMarker, IValueSet, IValue, IDomainElement
from clld.web.icon import MapMarker
from clldutils.svg import pie, icon, data_url

from agrobase import models


def main(global_config, **settings):
    config = Configurator(settings=settings)
    config.include('clld.web.app')
    config.include('agrobase.models')
    config.include('agrobase.adapters')
    config.include('agrobase.datatables')
    # если будет agrobase.maps с includeme, можно и его
    config.include('agrobase.maps')

    config.add_route('param_groups', '/param-groups')
    config.add_route('param_group', '/param-groups/{group}')
    config.add_route('param_hyper', '/param-groups/{group}/{parent}')

    config.add_route('agreement_table', '/agreement-table')
    config.add_route('feature_combinations', '/feature-combinations')
    config.add_route('feature_examples', '/feature-examples')


    config.scan()
    return config.make_wsgi_app()

