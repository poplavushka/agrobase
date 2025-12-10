<%inherit file="agrobase.mako"/>

<%block name="title">Combination of features</%block>

<h1>Combination of features</h1>

<p class="lead">
    Select up to three feature values; only languages matching all of them
    will be shown on the map and in the table.
</p>

<form method="get" class="form-horizontal">
  % for i in range(1, 4):
    <div class="control-group">
      <label class="control-label">Feature ${i}</label>
      <div class="controls">
        <select name="c${i}">
          <option value="">-- none --</option>
          % for p in params:
            % if p.domain:
              <optgroup label="${p.name} (${p.id})">
                % for de in p.domain:
                  <%
                    selected = (
                        i <= len(selected_codes)
                        and selected_codes[i-1] == de.id
                    )
                  %>
                  <option value="${de.id}" ${'selected' if selected else ''}>
                    ${de.name}
                  </option>
                % endfor
              </optgroup>
            % endif
          % endfor
        </select>
      </div>
    </div>
  % endfor

  <div class="form-actions">
    <button type="submit" class="btn btn-primary">Apply</button>
  </div>
</form>

% if active_codes:
  <hr/>

  <h2>Results</h2>

  % if map_:
    ${map_.render()}
  % endif

  % if languages:
    <h3>Matching languages</h3>
    <table class="table table-condensed table-striped">
      <thead>
        <tr>
          <th>Language</th>
          <th>Genetic</th>
        </tr>
      </thead>
      <tbody>
      % for lang in languages:
        <tr>
          <td><a href="${request.resource_url(lang)}">${lang.name}</a></td>
          <td>${(lang.jsondata or {}).get('genetic', '')}</td>
        </tr>
      % endfor
      </tbody>
    </table>
  % else:
    <p><em>No languages match the selected combination.</em></p>
  % endif
% endif
