<%inherit file="agrobase.mako"/>

<%block name="title">Parameters in ${group_id}</%block>

<h1>Parameters in group: ${group_id}</h1>

<ul>
% for p in params:
    % if group_id == 'agreement':
        ## Для agreement: это гиперпараметры, ведём на третий уровень
        <li>
            <a href="${request.route_url('param_hyper', group=group_id, parent=p.id)}">
                ${p.name} (${p.id})
            </a>
        </li>
    % else:
        ## Для language-metadata: сразу ведём на стандартную страничку параметра
        <li>
            <a href="${request.route_url('parameter', id=p.id)}">
                ${p.name} (${p.id})
            </a>
        </li>
    % endif
% endfor
</ul>
