<%! from pyramid.url import route_url %>

<%inherit file="agrobase.mako"/>

<%block name="title">Parameter groups</%block>

<h1>Parameter groups</h1>

<ul>
% for g in groups:
    <li>
        <a href="${request.route_url('param_group', group=g['id'])}">
            ${g['name']}
        </a>
    </li>
% endfor
</ul>
