<%inherit file="agrobase.mako"/>

<%block name="title">Agreement table</%block>

<h1>Agreement features</h1>

<p class="lead">
  Use the filters below to select languages with particular agreement profiles (See the results in a table below).
</p>

<div id="agreement-view-toggle" class="btn-toolbar" style="margin-bottom: 1em;">
  <div class="btn-group" data-toggle="buttons-radio">
    <button type="button"
            class="btn btn-large btn-primary btn-toggle active"
            data-view="table">
      Table view
    </button>
    <button type="button"
            class="btn btn-large btn-toggle"
            data-view="map">
      Map view
    </button>
  </div>
</div>

<%
  import collections, json

  def _family(l):
      jd = l.jsondata or {}
      return (jd.get('genetic_family') or jd.get('genetic') or '').strip() or 'Unknown'

  def _branch(l):
      jd = l.jsondata or {}
      return (jd.get('genetic_branch') or '').strip() or 'Unknown'

  # Family -> Branch -> [languages]
  tree = collections.defaultdict(lambda: collections.defaultdict(list))
  for l in languages:
      tree[_family(l)][_branch(l)].append(l)

  tree_sorted = []
  for fam in sorted(tree.keys()):
      branches = []
      for br in sorted(tree[fam].keys()):
          langs = sorted(tree[fam][br], key=lambda x: x.name)
          branches.append((br, langs))
      tree_sorted.append((fam, branches))

  agr_ids_json  = json.dumps([p.id for p in (agr_params or [])])
  meta_ids_json = json.dumps([p.id for p in (meta_params or [])])

  agr_param_ids_set = set([p.id for p in (agr_params or [])])
  meta_param_ids_set = set([p.id for p in (meta_params or [])])
%>

<div class="well" id="agreement-filter-panel">
  <h3 class="filter-main-title">Filter by features</h3>
  <p>
    Choose values for any subset of features. Features with <strong>Any</strong> are ignored.
  </p>

  % if agr_hyperparams:
    <fieldset class="filter-section">
      <legend class="filter-section-title">Agreement features</legend>

      % for hp in agr_hyperparams:
        <details class="feature-group">
          <summary class="feature-group-summary">
            <span class="param-info"
                  data-param-name="${hp.name}"
                  data-param-desc="${hp.description or ''}">
              ${hp.name}
            </span>
          </summary>

          ## ВАЖНО: как в старой версии — рендерим фильтр для hp только если по нему реально есть колонка в таблице
          % if hp.id in agr_param_ids_set:
            <label style="display: block; margin: 4px 0;">
              <span class="param-info"
                    data-param-name="${hp.name}"
                    data-param-desc="${hp.description or ''}">
                ${hp.name}
              </span>:
              <select class="feature-filter input-small"
                      data-group="agreement"
                      data-param-id="${hp.id}"
                      data-param-name="${hp.name}">
                <option value="">Any</option>
                % if hp.domain:
                  % for de in hp.domain:
                    <option value="${de.name}">${de.name}</option>
                  % endfor
                % endif
              </select>
            </label>
          % endif

          % for p in agr_children_map.get(hp.id, []):
            % if p.id in agr_param_ids_set:
              <label style="display: block; margin: 4px 0 4px 1.5em;">
                <span class="param-info"
                      data-param-name="${p.name}"
                      data-param-desc="${p.description or ''}">
                  ${p.name}
                </span>:
                <select class="feature-filter input-small"
                        data-group="agreement"
                        data-param-id="${p.id}"
                        data-param-name="${p.name}">
                  <option value="">Any</option>
                  % if p.domain:
                    % for de in p.domain:
                      <option value="${de.name}">${de.name}</option>
                    % endfor
                  % endif
                </select>
              </label>
            % endif
          % endfor
        </details>
      % endfor
    </fieldset>
  % endif

  <details class="filter-section filter-section-secondary" open>
    <summary class="filter-summary">Filter by languages</summary>

    <fieldset style="margin-top: 0.5em;">
      <legend class="filter-section-subtitle">Languages</legend>

      <div style="font-size: 90%; color: #555; margin-bottom: 0.5em;">
        Search by family, branch, or language name. If nothing is selected, all languages are included.
      </div>

      <input type="text"
             id="lang-tree-search"
             class="input-large"
             placeholder="Search family / branch / language..."
             style="display: block; margin-bottom: 0.5em;"/>

      <label class="checkbox" style="margin-bottom: 0.4em;">
        <input type="checkbox" id="lang-any" checked="checked"/>
        Any (all languages)
      </label>

      <div id="lang-tree"
           style="max-height: 260px; overflow-y: auto; border: 1px solid #ddd; padding: 6px; background: #fff;">

        % for fam, branches in tree_sorted:
          <details class="lang-node family-node"
                   data-kind="family"
                   data-search="${(fam or '').lower()}">
            <summary class="lang-node-summary">
              <label class="checkbox inline" style="margin: 0; font-weight: 600;">
                <input type="checkbox" class="family-checkbox"
                       data-family="${fam}"/>
                ${fam}
              </label>
            </summary>

            <div style="margin-left: 1.2em; margin-top: 0.25em;">
              % for br, langs in branches:
                <details class="lang-node branch-node"
                         data-kind="branch"
                         data-family="${fam}"
                         data-search="${((fam or '') + ' ' + (br or '')).lower()}">
                  <summary class="lang-node-summary">
                    <label class="checkbox inline" style="margin: 0;">
                      <input type="checkbox" class="branch-checkbox"
                             data-family="${fam}"
                             data-branch="${br}"/>
                      ${br}
                    </label>
                  </summary>

                  <div style="margin-left: 1.2em; margin-top: 0.25em;">
                    % for l in langs:
                      <label class="checkbox language-leaf"
                             data-kind="language"
                             data-family="${fam}"
                             data-branch="${br}"
                             data-search="${((fam or '') + ' ' + (br or '') + ' ' + (l.name or '')).lower()}">
                        <input type="checkbox"
                               class="language-checkbox"
                               value="${l.id}"
                               data-lang-name="${l.name}"/>
                        ${l.name}
                      </label>
                    % endfor
                  </div>
                </details>
              % endfor
            </div>
          </details>
        % endfor

      </div>
    </fieldset>
  </details>

  % if meta_params:
    <details class="filter-section filter-section-secondary">
      <summary class="filter-summary">Macro-parameters</summary>

      <fieldset style="margin-top: 0.5em;">
        <legend class="filter-section-subtitle">Macro-parameters</legend>
        % for p in meta_params:
          % if p.id in meta_param_ids_set:
            <label style="display: block; margin-bottom: 4px;">
              <span class="param-info"
                    data-param-name="${p.name}"
                    data-param-desc="${p.description or ''}">
                ${p.name}
              </span>:
              <select class="feature-filter input-small"
                      data-group="macro"
                      data-param-id="${p.id}"
                      data-param-name="${p.name}">
                <option value="">Any</option>
                % if p.domain:
                  % for de in p.domain:
                    <option value="${de.name}">${de.name}</option>
                  % endfor
                % endif
              </select>
            </label>
          % endif
        % endfor
      </fieldset>
    </details>
  % endif
</div>

<div id="agreement-filter-actions" class="filter-actions clearfix">
  <button type="button" id="show-full-table" class="btn btn-small pull-right">
    Show full table
  </button>

  % if meta_params:
    <button type="button" id="toggle-macro-columns" class="btn btn-small pull-right" style="margin-right: 0.5em;">
      Show macro-parameters
    </button>
  % endif

  <button type="button" id="toggle-all-agreement" class="btn btn-small pull-right" style="margin-right: 0.5em; display: none;">
    Show other agreement columns
  </button>

  <span class="help-block" style="margin-right: 18em;">
    If you click on "Show macro-parameters" --> they will appear at the end of the table.
    If you click on "Show full table" --> your filters will reset
  </span>
</div>

<div id="agreement-table-view">
  <div class="agreement-table-wrapper">
    <table id="agreement-table" class="table table-condensed table-striped">
      <thead>
        <tr>
          <th>Language</th>
          <th>Genetic/Family</th>
          <th>Genetic/Branch</th>

          % for p in (agr_params or []):
            <th class="col-agr" data-param-id="${p.id}">${p.name}</th>
          % endfor

          % for p in (meta_params or []):
            <th class="col-macro" data-param-id="${p.id}">${p.name}</th>
          % endfor
        </tr>
      </thead>
      <tbody>
      % for lang in languages:
        <%
          jd = lang.jsondata or {}
          fam = (jd.get('genetic_family') or jd.get('genetic') or '').strip() or 'Unknown'
          br  = (jd.get('genetic_branch') or '').strip() or 'Unknown'

          _lat = getattr(lang, 'latitude', None)
          _lon = getattr(lang, 'longitude', None)
          if _lat in (None, ''):
              _lat = jd.get('latitude') or jd.get('Latitude') or ''
          if _lon in (None, ''):
              _lon = jd.get('longitude') or jd.get('Longitude') or ''
        %>
        <tr data-lang-id="${lang.id}"
            data-family="${fam}"
            data-branch="${br}"
            data-lat="${_lat}"
            data-lon="${_lon}">
          <td><a href="${request.resource_url(lang)}">${lang.name}</a></td>
          <td>${fam}</td>
          <td>${br}</td>

          % for p in (agr_params or []):
            <td class="feature-cell col-agr"
                data-param-id="${p.id}"
                data-param-name="${p.name}">
              ${value_map.get((lang.pk, p.pk), '')}
            </td>
          % endfor

          % for p in (meta_params or []):
            <td class="feature-cell col-macro"
                data-param-id="${p.id}"
                data-param-name="${p.name}">
              ${value_map.get((lang.pk, p.pk), '')}
            </td>
          % endfor
        </tr>
      % endfor
      </tbody>
    </table>
  </div>
</div>

<div id="agreement-map-view" style="display: none; margin-top: 1em;">
  <div id="agreement-map" style="height: 480px; margin-bottom: 0.5em;"></div>

  <div class="checkbox" style="margin-bottom: 0.5em;">
    <label>
      <input type="checkbox" id="map-include-other-values"/>
      Include languages with other values for these features
    </label>
    <p class="muted" style="margin: 0.25em 0 0;">
      Table stays filtered; the map adds languages with other values of the same features.
    </p>
  </div>

  <div id="agreement-map-legend" class="well well-small">
    <p class="muted">
      <em>Legend will appear here once the map is drawn. It uses only features with non-Any values.</em>
    </p>
  </div>
</div>

<div id="feature-modal" class="modal hide fade">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Feature info</h3>
  </div>
  <div class="modal-body">
    <p></p>
  </div>
</div>

<style>
  #agreement-filter-panel { margin-bottom: 1em; }
  #agreement-filter-panel fieldset { border: none; padding: 0; margin: 0 0 0.75em; }
  #agreement-filter-panel legend { font-size: 14px; font-weight: bold; margin-bottom: 0.35em; }
  #agreement-filter-panel legend.filter-section-title { font-size: 22px; font-weight: 700; margin-bottom: 0.7em; }

  .agreement-table-wrapper { overflow-x: auto; padding-top: 0.5em; border-top: 1px solid #eee; }
  #agreement-table { border-collapse: collapse; width: auto; }
  #agreement-table th, #agreement-table td {
    font-size: 11px; padding: 3px 4px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  #agreement-table th { white-space: normal; word-wrap: break-word; }

  #agreement-table th:nth-child(-n+3),
  #agreement-table td:nth-child(-n+3) { min-width: 160px; white-space: normal; }
  #agreement-table th:nth-child(n+4),
  #agreement-table td:nth-child(n+4) { max-width: 90px; }

  #agreement-table th.col-macro,
  #agreement-table td.col-macro { display: none; }

  .param-info { cursor: help; border-bottom: 1px dotted #999; color: #444; }
  .param-info:hover { color: #0056b3; }

  #agreement-table td.feature-cell { cursor: pointer; text-decoration: underline; text-decoration-style: dotted; text-decoration-thickness: 1px; }
  #agreement-table td.feature-cell:hover { background-color: #fff8dc !important; }

  .filter-main-title { margin-top: 0; font-size: 20px; font-weight: 600; }
  .filter-section { margin-bottom: 0.75em; }
  .filter-section-title { font-size: 22px; font-weight: 700; margin-bottom: 0.7em; }
  .filter-section-subtitle { font-size: 15px; font-weight: 600; margin-bottom: 0.4em; }

  .filter-section-secondary { border-top: 1px solid #ddd; padding-top: 0.75em; margin-top: 0.75em; }
  details summary::-webkit-details-marker { display: none; }

  .feature-group-summary, .filter-summary, .lang-node-summary {
    cursor: pointer; padding: 6px 0; margin: 0; list-style: none; font-weight: 600; font-size: 15px;
  }
  .feature-group-summary::before, .filter-summary::before, .lang-node-summary::before {
    content: '▸'; display: inline-block; margin-right: 8px; font-size: 18px; line-height: 1; vertical-align: middle;
    transition: transform 0.15s ease; color: #444; font-weight: 700;
  }
  details[open] > .feature-group-summary::before,
  details[open] > .filter-summary::before,
  details[open] > .lang-node-summary::before { transform: rotate(90deg); }

  #agreement-filter-actions { margin-top: 0.75em; margin-bottom: 0.5em; }

  #agreement-view-toggle .btn-toggle { font-size: 14px; padding: 6px 18px; }
  #agreement-view-toggle .btn-toggle.btn-primary { background-color: #4e8cd4; border-color: #417fca; }
  #agreement-view-toggle .btn-toggle.btn-primary:hover,
  #agreement-view-toggle .btn-toggle.btn-primary:focus { background-color: #447fc3; border-color: #386fae; }

  .agreement-map-marker .map-marker-symbol { font-size: 18px; line-height: 20px; }
  #agreement-map-legend .legend-item { margin-bottom: 3px; }
  #agreement-map-legend .legend-symbol { display: inline-block; width: 18px; text-align: center; margin-right: 4px; }
</style>

<script type="text/javascript">
(function () {
  // Ждем jQuery даже если он подключается позже (типично для базового шаблона)
  function bootWhenJQueryReady() {
    if (!window.jQuery) {
      setTimeout(bootWhenJQueryReady, 30);
      return;
    }

    var jq = window.jQuery;
    jq(function () {
      var $ = jq;

      function escapeHtml(text) {
        return $('<div/>').text(text || '').html();
      }

      function stripOuterQuotes(text) {
        if (!text) return '';
        text = ('' + text).trim();
        if (!text) return '';
        var first = text.charAt(0);
        var last = text.charAt(text.length - 1);
        var pairs = {'"':'"', "'":"'", '«':'»', '“':'”', '„':'“', '‘':'’'};
        if (pairs[first] && last === pairs[first]) {
          return text.substring(1, text.length - 1).trim();
        }
        return text;
      }

      function norm(s) {
        s = (s == null) ? '' : ('' + s);
        s = s.replace(/\u00A0/g, ' ');     // NBSP -> space
        s = stripOuterQuotes(s);
        s = s.trim().toLowerCase();
        s = s.replace(/\s+/g, ' ');
        return s;
      }

      var ALL_AGR_PARAM_IDS  = ${agr_ids_json|n};
      var ALL_META_PARAM_IDS = ${meta_ids_json|n};

      var showMacroColumns = false;
      var showAllAgreementColumns = false;

      function markRowFiltered($row, filteredOut) {
        $row.toggleClass('filtered-out', !!filteredOut);
        $row.toggle(!filteredOut);
      }

      // --- Table/Map toggle ---
      $(document).on('click', '#agreement-view-toggle button', function (e) {
        e.preventDefault();
        var view = $(this).data('view');

        $('#agreement-view-toggle button').removeClass('active');
        $(this).addClass('active');

        if (view === 'table') {
          $('#agreement-table-view').show();
          $('#agreement-map-view').hide();
        } else {
          $('#agreement-table-view').hide();
          $('#agreement-map-view').show();
          ensureMapInitialized();
          setTimeout(function () {
            if (agreementMap) agreementMap.invalidateSize();
            updateMapFromTable();
          }, 0);
        }
      });

      // --- active feature filters (agreement + macro) ---
      function getActiveFeatureFilters() {
        var filters = [];
        $('.feature-filter').each(function () {
          var val = $(this).val();
          if (!val) return;
          filters.push({
            group: '' + ($(this).data('group') || ''),
            paramId: '' + ($(this).data('param-id') || ''),
            paramName: '' + ($(this).data('param-name') || ''),
            value: '' + val
          });
        });
        filters.sort(function (a, b) {
          if (a.paramName < b.paramName) return -1;
          if (a.paramName > b.paramName) return 1;
          return 0;
        });
        return filters;
      }

      function activeAgreementFilterIds() {
        var ids = [];
        $('.feature-filter[data-group="agreement"]').each(function () {
          var val = $(this).val();
          if (!val) return;
          ids.push('' + ($(this).data('param-id') || ''));
        });
        return ids;
      }

      function activeMacroFilterIds() {
        var ids = [];
        $('.feature-filter[data-group="macro"]').each(function () {
          var val = $(this).val();
          if (!val) return;
          ids.push('' + ($(this).data('param-id') || ''));
        });
        return ids;
      }

      function setParamColumnVisible(paramId, visible) {
        var pid = '' + paramId;
        $('#agreement-table th[data-param-id="' + pid + '"], #agreement-table td[data-param-id="' + pid + '"]')
          .toggle(!!visible);
      }

      function updateColumnVisibility() {
        var agrActiveIds = activeAgreementFilterIds();
        var anyAgrActive = agrActiveIds.length > 0;

        if (anyAgrActive) {
          $('#toggle-all-agreement').show();
        } else {
          $('#toggle-all-agreement').hide();
          showAllAgreementColumns = false;
        }

        // AGREEMENT columns
        if (!anyAgrActive) {
          for (var i = 0; i < ALL_AGR_PARAM_IDS.length; i++) {
            setParamColumnVisible(ALL_AGR_PARAM_IDS[i], true);
          }
        } else {
          if (showAllAgreementColumns) {
            for (var j = 0; j < ALL_AGR_PARAM_IDS.length; j++) {
              setParamColumnVisible(ALL_AGR_PARAM_IDS[j], true);
            }
            $('#toggle-all-agreement').text('Hide other agreement columns');
          } else {
            for (var k = 0; k < ALL_AGR_PARAM_IDS.length; k++) {
              var pid = '' + ALL_AGR_PARAM_IDS[k];
              setParamColumnVisible(pid, $.inArray(pid, agrActiveIds) !== -1);
            }
            $('#toggle-all-agreement').text('Show other agreement columns');
          }
        }

        // MACRO columns
        if (!$('#toggle-macro-columns').length) return;

        if (!showMacroColumns) {
          for (var m = 0; m < ALL_META_PARAM_IDS.length; m++) {
            setParamColumnVisible(ALL_META_PARAM_IDS[m], false);
          }
          $('#toggle-macro-columns').text('Show macro-parameters');
        } else {
          var macroActiveIds = activeMacroFilterIds();
          if (macroActiveIds.length) {
            for (var n = 0; n < ALL_META_PARAM_IDS.length; n++) {
              var mpid = '' + ALL_META_PARAM_IDS[n];
              setParamColumnVisible(mpid, $.inArray(mpid, macroActiveIds) !== -1);
            }
          } else {
            for (var q = 0; q < ALL_META_PARAM_IDS.length; q++) {
              setParamColumnVisible(ALL_META_PARAM_IDS[q], true);
            }
          }
          $('#toggle-macro-columns').text('Hide macro-parameters');
        }
      }

      // --- Language tree: Any logic + cascade ---
      function syncAnyCheckbox() {
        var anyChecked = $('.language-checkbox:checked').length === 0;
        $('#lang-any').prop('checked', anyChecked);
      }

      $(document).on('change', '#lang-any', function () {
        if ($(this).is(':checked')) {
          $('.family-checkbox, .branch-checkbox, .language-checkbox').prop('checked', false);
          applyAllFilters();
        }
      });

      $(document).on('change', '.language-checkbox', function () {
        if ($(this).is(':checked')) $('#lang-any').prop('checked', false);
        else syncAnyCheckbox();
        applyAllFilters();
      });

      $(document).on('change', '.family-checkbox', function () {
        var fam = $(this).data('family');
        var checked = $(this).is(':checked');
        $('#lang-any').prop('checked', false);
        $('.branch-checkbox[data-family="' + fam + '"]').prop('checked', checked);
        $('.language-leaf[data-family="' + fam + '"] .language-checkbox').prop('checked', checked);
        if (!checked) syncAnyCheckbox();
        applyAllFilters();
      });

      $(document).on('change', '.branch-checkbox', function () {
        var fam = $(this).data('family');
        var br  = $(this).data('branch');
        var checked = $(this).is(':checked');
        $('#lang-any').prop('checked', false);
        $('.language-leaf[data-family="' + fam + '"][data-branch="' + br + '"] .language-checkbox')
          .prop('checked', checked);
        if (!checked) syncAnyCheckbox();
        applyAllFilters();
      });

      $(document).on('keyup', '#lang-tree-search', function () {
        var term = (($(this).val() || '') + '').toLowerCase().trim();
        if (!term) {
          $('#lang-tree .lang-node, #lang-tree .language-leaf').show();
          return;
        }

        $('#lang-tree .family-node').hide();
        $('#lang-tree .branch-node').hide();
        $('#lang-tree .language-leaf').hide();

        $('#lang-tree [data-search]').each(function () {
          var $el = $(this);
          var hay = (($el.data('search') || '') + '');
          if (hay.indexOf(term) !== -1) {
            $el.show();
            $el.parents('.family-node, .branch-node').show();
          }
        });
      });

      // --- Apply all filters (rows) ---
      function applyAllFilters() {
        var featureFilters = getActiveFeatureFilters();

        var langAny = $('#lang-any').is(':checked');
        var selectedLangIds = [];
        $('.language-checkbox:checked').each(function () {
          selectedLangIds.push('' + $(this).val());
        });

        $('#agreement-table tbody tr').each(function () {
          var $row = $(this);
          var visible = true;

          var rowLangId = '' + ($row.data('lang-id') || '');

          if (!langAny && selectedLangIds.length) {
            if ($.inArray(rowLangId, selectedLangIds) === -1) visible = false;
          }

          if (visible && featureFilters.length) {
            for (var i = 0; i < featureFilters.length; i++) {
              var f = featureFilters[i];
              var $cell = $row.find('td.feature-cell[data-param-id="' + f.paramId + '"]');
              var cellVal = norm($cell.text());
              var wantVal = norm(f.value);

              if (!cellVal || cellVal !== wantVal) {
                visible = false;
                break;
              }
            }
          }

          markRowFiltered($row, !visible);
        });

        updateColumnVisibility();

        if ($('#agreement-map-view').is(':visible') && agreementMap) {
          updateMapFromTable();
        }
      }

      $(document).on('change', '.feature-filter', applyAllFilters);

      // Buttons
      $(document).on('click', '#toggle-macro-columns', function (e) {
        e.preventDefault();
        showMacroColumns = !showMacroColumns;
        updateColumnVisibility();
      });

      $(document).on('click', '#toggle-all-agreement', function (e) {
        e.preventDefault();
        showAllAgreementColumns = !showAllAgreementColumns;
        updateColumnVisibility();
      });

      $(document).on('click', '#show-full-table', function (e) {
        e.preventDefault();

        $('.feature-filter').val('');
        $('.family-checkbox, .branch-checkbox, .language-checkbox').prop('checked', false);
        $('#lang-any').prop('checked', true);
        $('#lang-tree-search').val('');
        $('#lang-tree .lang-node, #lang-tree .language-leaf').show();

        $('#agreement-table tbody tr').removeClass('filtered-out').show();

        showMacroColumns = true;
        showAllAgreementColumns = true;
        updateColumnVisibility();

        if ($('#agreement-map-view').is(':visible') && agreementMap) {
          updateMapFromTable();
        }
      });

      // --- Modal: feature info ---
      $(document).on('click', '.param-info', function (e) {
        e.preventDefault();
        var name = $(this).data('param-name');
        var desc = $(this).data('param-desc') || 'No description available.';
        $('#feature-modal .modal-header h3').text(name);
        $('#feature-modal .modal-body').html('<p>' + escapeHtml(desc) + '</p>');
        $('#feature-modal').modal('show');
      });

      // --- Modal: examples ---
      var featureExamplesUrl = "${request.route_url('feature_examples')}";

      $(document).on('click', '#agreement-table td.feature-cell', function () {
        var value = $.trim($(this).text());
        if (!value) return;

        var $cell = $(this);
        var paramId = '' + ($cell.data('param-id') || '');
        var paramName = $cell.data('param-name');
        var $row = $cell.closest('tr');
        var langId = $row.data('lang-id');
        var langName = $.trim($row.find('td').eq(0).text());

        $('#feature-modal .modal-header h3').text(paramName + ' = ' + value + ' — ' + langName);
        $('#feature-modal .modal-body').html('<p><em>Loading examples…</em></p>');
        $('#feature-modal').modal('show');

        $.getJSON(featureExamplesUrl, {lang: langId, param: paramId}, function (data) {
          if (!data.ok || !data.examples || !data.examples.length) {
            $('#feature-modal .modal-body').html('<p><em>No examples available for this cell.</em></p>');
            return;
          }
          var html = '';
          $.each(data.examples, function (i, ex) {
            html += '<div class="example">';

            var primary = stripOuterQuotes(ex.primary || '');
            var gloss   = stripOuterQuotes(ex.gloss || '');
            var trans   = stripOuterQuotes(ex.translation || '');

            if (primary || gloss) {
              html += '<div class="ig-example">';
              if (primary) html += '<pre>' + escapeHtml(primary) + '</pre>';
              if (gloss)   html += '<pre>' + escapeHtml(gloss)   + '</pre>';
              html += '</div>';
            }

            if (trans) {
              html += '<p class="ig-translation">&#8216;' + escapeHtml(trans) + '&#8217;</p>';
            }

            if (ex.url) {
              html += '<p><a href="' + ex.url + '">View example page</a></p>';
            }

            html += '</div>';
            if (i < data.examples.length - 1) html += '<hr/>';
          });
          $('#feature-modal .modal-body').html(html);
        }).fail(function () {
          $('#feature-modal .modal-body').html('<p><em>Error loading examples.</em></p>');
        });
      });

      // -------- MAP ------------
      var agreementMap = null;
      var agreementMapLayer = null;
      var markerColors = ['#6baed6', '#9ecae1', '#74c476', '#a1d99b', '#fbb4b9', '#fdd0a2', '#bcbddc', '#c7e9c0', '#f2f0f7'];
      var markerShapes = ['circle', 'square', 'triangle', 'diamond', 'star'];
      var shapeChars = {circle:'●', square:'■', triangle:'▲', diamond:'◆', star:'★'};

      function getCategoryStyle(index) {
        var color = markerColors[index % markerColors.length];
        var shape = markerShapes[Math.floor(index / markerColors.length) % markerShapes.length];
        return {color: color, shape: shape};
      }

      function makeIconForStyle(style) {
        if (typeof L === 'undefined') return null;
        var symbol = shapeChars[style.shape] || '●';
        var html = '<span class="map-marker-symbol" style="color:' + style.color + ';">' + symbol + '</span>';
        return L.divIcon({ className: 'agreement-map-marker', html: html, iconSize: [20, 20], iconAnchor: [10, 10] });
      }

      function renderLegend(categories) {
        var $legend = $('#agreement-map-legend');
        if (!categories.length) {
          $legend.html('<p class="muted"><em>No languages to show on the map for the current filters.</em></p>');
          return;
        }
        var total = 0;
        $.each(categories, function (i, cat) { total += cat.count; });

        var html = '<strong>Legend</strong> <span class="muted">(languages on map: ' + total + ')</span><ul class="unstyled">';
        $.each(categories, function (i, cat) {
          var symbol = shapeChars[cat.style.shape] || '●';
          html += '<li class="legend-item">' +
                  '<span class="legend-symbol" style="color:' + cat.style.color + ';">' + symbol + '</span>' +
                  escapeHtml(cat.label || 'All languages') + ' — ' +
                  '<span class="badge">' + cat.count + '</span>' +
                  '</li>';
        });
        html += '</ul>';
        $legend.html(html);
      }

      function rowsForMap() {
        var useAllRows = $('#map-include-other-values').is(':checked');
        var $rows = $('#agreement-table tbody tr');
        if (useAllRows) return $rows;
        return $rows.filter(function () { return !$(this).hasClass('filtered-out'); });
      }

      function updateMapFromTable() {
        if (!agreementMap || !agreementMapLayer) return;

        agreementMapLayer.clearLayers();
        var activeFilters = getActiveFeatureFilters();
        var categoriesByKey = {};
        var categories = [];

        rowsForMap().each(function () {
          var $row = $(this);

          var lat = parseFloat($row.attr('data-lat'));
          var lon = parseFloat($row.attr('data-lon'));
          if (isNaN(lat) || isNaN(lon)) return;

          var langName = $.trim($row.find('td').eq(0).text());
          var key, label;

          if (activeFilters.length) {
            var keyParts = [];
            var labelParts = [];
            for (var j = 0; j < activeFilters.length; j++) {
              var f = activeFilters[j];
              var $cell = $row.find('td.feature-cell[data-param-id="' + f.paramId + '"]');
              var val = norm($cell.text()) || 'n/a';
              keyParts.push(f.paramId + ':' + val);
              labelParts.push((f.paramName || 'Feature') + ' = ' + val);
            }
            key = keyParts.join('|');
            label = labelParts.join(', ');
          } else {
            key = '__all__';
            label = 'All languages (current filters)';
          }

          if (!categoriesByKey[key]) {
            var idx = categories.length;
            categoriesByKey[key] = { key: key, label: label, count: 0, style: getCategoryStyle(idx) };
            categories.push(categoriesByKey[key]);
          }

          var cat = categoriesByKey[key];
          cat.count++;

          var icon = makeIconForStyle(cat.style);
          if (!icon) return;

          var popup = '<strong>' + escapeHtml(langName) + '</strong>';
          if (label) popup += '<br/>' + escapeHtml(label);

          agreementMapLayer.addLayer(L.marker([lat, lon], {icon: icon}).bindPopup(popup));
        });

        if (agreementMapLayer.getLayers().length) {
          try { agreementMap.fitBounds(agreementMapLayer.getBounds().pad(0.1)); } catch (e) {}
        }

        renderLegend(categories);
      }

      function ensureMapInitialized() {
        if (typeof L === 'undefined') {
          $('#agreement-map').html('<p class="text-error"><em>Map library (Leaflet) is not available.</em></p>');
          return;
        }

        if (!agreementMap) {
          agreementMap = L.map('agreement-map', {attributionControl: false});
          agreementMapLayer = L.layerGroup().addTo(agreementMap);

          L.tileLayer(
            'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
            {maxZoom: 16}
          ).addTo(agreementMap);

          L.control.attribution({ position: 'bottomright', prefix: '' })
            .addTo(agreementMap)
            .addAttribution('Tiles © Esri — Esri, DeLorme, NAVTEQ');

          agreementMap.setView([20, 0], 2);
        }
      }

      $(document).on('change', '#map-include-other-values', function () {
        if ($('#agreement-map-view').is(':visible') && agreementMap) updateMapFromTable();
      });

      // initial
      syncAnyCheckbox();
      updateColumnVisibility();
      applyAllFilters();
    });
  }

  bootWhenJQueryReady();
})();
</script>
