<%inherit file="agrobase.mako"/>

<%block name="title">${hyperparam.name}</%block>

<h1>${hyperparam.name} (${hyperparam.id})</h1>

<p>Subparameters:</p>

<table class="table table-condensed">
  <thead>
    <tr>
      <th>Parameter</th>
      <th>ID</th>
    </tr>
  </thead>
  <tbody>
  % for p in params:
    <tr>
      <td>
        <a href="${request.route_url('parameter', id=p.id)}">
          ${p.name}
        </a>
      </td>
      <td>${p.id}</td>
    </tr>
  % endfor
  </tbody>
</table>
