<%inherit file="agrobase.mako"/>

<%block name="title">Agreement & metadata table</%block>

<h1>Agreement features</h1>

<p class="lead">
    Use the filters below to select languages with particular agreement profiles.
</p>

<!-- Переключатель вида результата: таблица / карта -->
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

<!-- чекбоксы: какие группы признаков показывать как колонки -->
<form class="form-inline" method="get" style="margin-bottom: 1em;">
  <label class="checkbox inline">
    <input type="hidden" name="show_meta" value="0"/>
    <input type="checkbox" name="show_meta" value="1"
           ${'checked' if show_meta else ''}/>
    Show language metadata
  </label>

  <label class="checkbox inline" style="margin-left: 1em;">
    <input type="hidden" name="show_agr" value="0"/>
    <input type="checkbox" name="show_agr" value="1"
           ${'checked' if show_agr else ''}/>
    Show agreement features
  </label>

  <button type="submit" class="btn" style="margin-left: 1em;">
    Update
  </button>
</form>

<%
    # уникальные генетические семьи для фильтра
    families = sorted({
        (l.jsondata or {}).get('genetic', '')
        for l in languages
        if (l.jsondata or {}).get('genetic', '')
    })

    # Мэппинг: pk параметра -> индекс колонки в таблице agreement-table
    # 0 = Language, 1 = Genetic, дальше подряд meta, потом agreement
    param_col_index = {}
    col = 2
    if show_meta:
        for p in meta_params:
            param_col_index[p.pk] = col
            col += 1
    if show_agr:
        for p in agr_params:
            param_col_index[p.pk] = col
            col += 1
%>

<div class="well" id="agreement-filter-panel">
  <h3 class="filter-main-title">Filter by features</h3>
  <p>
    Choose values for any subset of features. Columns with <strong>Any</strong> are ignored.
  </p>

  <!-- 1. Agreement features – всегда видны -->
  % if show_agr and agr_hyperparams:
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

          <% col_hp = param_col_index.get(hp.pk) %>
          % if col_hp is not None:
            <label style="display: block; margin: 4px 0;">
              <span class="param-info"
                    data-param-name="${hp.name}"
                    data-param-desc="${hp.description or ''}">
                ${hp.name}
              </span>:
              <select class="feature-filter input-small"
                      data-column="${col_hp}"
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
            <% col_index = param_col_index.get(p.pk) %>
            % if col_index is not None:
              <label style="display: block; margin: 4px 0 4px 1.5em;">
                <span class="param-info"
                      data-param-name="${p.name}"
                      data-param-desc="${p.description or ''}">
                  ${p.name}
                </span>:
                <select class="feature-filter input-small"
                        data-column="${col_index}"
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
  % else:
    <p class="muted">
      Turn on <strong>Show agreement features</strong> above to filter by them.
    </p>
  % endif

  <!-- 2. Фильтр по языкам / генетике в раскрывающемся блоке -->
  <details class="filter-section filter-section-secondary">
    <summary class="filter-summary">
      Filter by languages &amp; families
    </summary>

    <fieldset style="margin-top: 0.5em;">
      <legend class="filter-section-subtitle">Languages and genetic</legend>

      <div style="font-size: 90%; color: #555; margin-bottom: 0.5em;">
        Check any number of languages / families.<br/>
        If <strong>Any</strong> is checked, the corresponding filter is ignored.
      </div>

      <!-- Языки -->
      <div style="display: inline-block; margin-right: 2em; vertical-align: top;">
        <label>
          Language:
          <input type="text"
                 id="language-filter-search"
                 class="input-medium"
                 placeholder="Search languages..."
                 style="display: block; margin-bottom: 0.3em;"/>
          <div id="language-checkboxes"
               style="max-height: 180px; overflow-y: auto; border: 1px solid #ddd; padding: 4px;">
            <label class="checkbox">
              <input type="checkbox" class="language-checkbox" value="" checked="checked"/>
              Any
            </label>
            % for lang in languages:
              <label class="checkbox">
                <input type="checkbox" class="language-checkbox" value="${lang.name}"/>
                ${lang.name}
              </label>
            % endfor
          </div>
        </label>
      </div>

      <!-- Генетика -->
      <div style="display: inline-block; vertical-align: top;">
        <label>
          Genetic:
          <input type="text"
                 id="genetic-filter-search"
                 class="input-medium"
                 placeholder="Search families..."
                 style="display: block; margin-bottom: 0.3em;"/>
          <div id="genetic-checkboxes"
               style="max-height: 180px; overflow-y: auto; border: 1px solid #ddd; padding: 4px;">
            <label class="checkbox">
              <input type="checkbox" class="genetic-checkbox" value="" checked="checked"/>
              Any
            </label>
            % for fam in families:
              <label class="checkbox">
                <input type="checkbox" class="genetic-checkbox" value="${fam}"/>
                ${fam}
              </label>
            % endfor
          </div>
        </label>
      </div>
    </fieldset>
  </details>

  <!-- 3. Metadata – отдельный блок -->
  % if show_meta and meta_params:
    <details class="filter-section filter-section-secondary">
      <summary class="filter-summary">
        Filter by language metadata
      </summary>

      <fieldset style="margin-top: 0.5em;">
        <legend class="filter-section-subtitle">Language metadata</legend>
        % for p in meta_params:
          <% col_index = param_col_index.get(p.pk) %>
          % if col_index is not None:
            <label style="display: block; margin-bottom: 4px;">
              <span class="param-info"
                    data-param-name="${p.name}"
                    data-param-desc="${p.description or ''}">
                ${p.name}
              </span>:
              <select class="feature-filter input-small"
                      data-column="${col_index}"
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

<!-- Кнопка "Show full table" и подпись выносим ПОД серый блок -->
<div id="agreement-filter-actions" class="filter-actions clearfix">
  <button id="show-full-table" class="btn btn-small pull-right">
    Show full table
  </button>
  <span class="help-block" style="margin-right: 6em;">
    Reset all filters and show all columns.
  </span>
</div>

<!-- ВИД 1: таблица -->
<div id="agreement-table-view">
  <div class="agreement-table-wrapper">
    <table id="agreement-table" class="table table-condensed table-striped">
      <thead>
        <tr>
          <th>Language</th>
          <th>Genetic</th>
          % if show_meta:
            % for p in meta_params:
              <th>${p.name}</th>
            % endfor
          % endif
          % if show_agr:
            % for p in agr_params:
              <th>${p.name}</th>
            % endfor
          % endif
        </tr>
      </thead>
      <tbody>
      % for lang in languages:
        <%  # координаты: стараемся вытащить из разных возможных полей
            _lat = getattr(lang, 'latitude', '')
            _lon = getattr(lang, 'longitude', '')
            jd = lang.jsondata or {}
            if _lat in (None, ''):
                _lat = jd.get('latitude') or jd.get('Latitude') or ''
            if _lon in (None, ''):
                _lon = jd.get('longitude') or jd.get('Longitude') or ''
        %>
        <tr data-lang-id="${lang.id}"
            data-lat="${_lat}"
            data-lon="${_lon}">
          <!-- первые две колонки: только язык и генетика -->
          <td><a href="${request.resource_url(lang)}">${lang.name}</a></td>
          <td>${(lang.jsondata or {}).get('genetic', '')}</td>

          % if show_meta:
            % for p in meta_params:
              <td class="feature-cell"
                  data-param-id="${p.id}"
                  data-param-name="${p.name}">
                ${value_map.get((lang.pk, p.pk), '')}
              </td>
            % endfor
          % endif

          % if show_agr:
            % for p in agr_params:
              <td class="feature-cell"
                  data-param-id="${p.id}"
                  data-param-name="${p.name}">
                ${value_map.get((lang.pk, p.pk), '')}
              </td>
            % endfor
          % endif
        </tr>
      % endfor
      </tbody>
    </table>
  </div>
</div>

<!-- ВИД 2: карта -->
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

<!-- Модальное окно для описаний признаков и примеров -->
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
  .example {
    margin-bottom: 0.8em;
  }
  .ig-example pre {
    margin: 0;
    font-family: monospace;
    white-space: pre-wrap;
  }
  .ig-translation {
    margin-top: 0.25em;
  }

  #agreement-filter-panel {
    margin-bottom: 1em;
  }
  #agreement-filter-panel fieldset {
    border: none;
    padding: 0;
    margin: 0 0 0.75em;
  }
  /* общий стиль для legend в панели */
  #agreement-filter-panel legend {
    font-size: 14px;
    font-weight: bold;
    margin-bottom: 0.35em;
  }
  /* а для Agreement features — покрупнее */
  #agreement-filter-panel legend.filter-section-title {
    font-size: 22px;
    font-weight: 700;
    margin-bottom: 0.7em;
  }

  #agreement-filter-panel .filter-column {
    margin-bottom: 0.75em;
  }

  @media (max-width: 979px) {
    #agreement-filter-panel .filter-column-left,
    #agreement-filter-panel .filter-column-right {
      float: none;
      width: 100%;
      margin-left: 0;
    }
  }

    .agreement-table-wrapper {
      overflow-x: auto;
      padding-top: 0.5em;
      border-top: 1px solid #eee;
    }

    /* НЕ фиксируем ширину таблицы, чтобы первые колонки не сжимались до нуля */
    #agreement-table {
      border-collapse: collapse;
      width: auto;
    }

    #agreement-table th,
    #agreement-table td {
      font-size: 11px;
      padding: 3px 4px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    #agreement-table th {
      white-space: normal;
      word-wrap: break-word;   /* заголовки могут быть многострочными */
    }

/* Language и Genetic делаем пошире и не даём их съесть */
#agreement-table th:nth-child(-n+2),
#agreement-table td:nth-child(-n+2) {
min-width: 140px;
    white-space: normal;
}

/* для всех остальных колонок только ограничиваем максимум */
#agreement-table th:nth-child(n+3),
#agreement-table td:nth-child(n+3) {
  max-width: 90px;
}


  .param-info {
    cursor: help;
    border-bottom: 1px dotted #999;
    color: #444;
  }
  .param-info:hover {
    color: #0056b3;
  }

  #agreement-table td.feature-cell {
    cursor: pointer;
    text-decoration: underline;
    text-decoration-style: dotted;
    text-decoration-thickness: 1px;
  }

  #agreement-table td.feature-cell:hover {
    background-color: #fff8dc !important;
  }

  .agreement-map-marker .map-marker-symbol {
    font-size: 18px;
    line-height: 20px;
  }
  #agreement-map-legend .legend-item {
    margin-bottom: 3px;
  }
  #agreement-map-legend .legend-symbol {
    display: inline-block;
    width: 18px;
    text-align: center;
    margin-right: 4px;
  }

  /* главный заголовок панели фильтров */
  .filter-main-title {
    margin-top: 0;
    font-size: 20px;
    font-weight: 600;
  }

  .filter-section {
    margin-bottom: 0.75em;
  }

  .filter-section-title {
    font-size: 22px;
    font-weight: 700;
    margin-bottom: 0.7em;
  }

  .filter-section-subtitle {
    font-size: 15px;
    font-weight: 600;
    margin-bottom: 0.4em;
  }

  /* разделители для нижних блоков (languages / metadata) */
  .filter-section-secondary {
    border-top: 1px solid #ddd;
    padding-top: 0.75em;
    margin-top: 0.75em;
  }

  /* аккуратные стрелочки у раскрывающихся блоков */
  details summary::-webkit-details-marker {
    display: none;
  }

  .feature-group-summary,
  .filter-summary {
    cursor: pointer;
    padding: 6px 0;
    margin: 0;
    list-style: none;
    font-weight: 600;
    font-size: 15px;
  }

  .feature-group-summary::before,
  .filter-summary::before {
    content: '▸';
    display: inline-block;
    margin-right: 8px;
    font-size: 18px;
    line-height: 1;
    vertical-align: middle;
    transition: transform 0.15s ease;
    color: #444;
    font-weight: 700;
  }

  details[open] > .feature-group-summary::before,
  details[open] > .filter-summary::before {
    transform: rotate(90deg);
  }

  /* внутри summary название фичи чуть крупнее */
  .feature-group-summary .param-info {
    font-size: 14px;
    font-weight: 600;
  }

  /* блок с кнопкой "Show full table" под фильтрами */
  #agreement-filter-actions {
    margin-top: 0.75em;
    margin-bottom: 0.5em;
  }

  /* Крупные кнопки переключения Table / Map и мягкий синий */
  #agreement-view-toggle .btn-toggle {
    font-size: 14px;
    padding: 6px 18px;
  }

  #agreement-view-toggle .btn-toggle.btn-primary {
    background-color: #4e8cd4;   /* мягкий синий */
    border-color: #417fca;
  }

  #agreement-view-toggle .btn-toggle.btn-primary:hover,
  #agreement-view-toggle .btn-toggle.btn-primary:focus {
    background-color: #447fc3;
    border-color: #386fae;
  }
</style>

<script type="text/javascript">
  $(function () {
    function escapeHtml(text) {
      return $('<div/>').text(text || '').html();
    }

    function stripOuterQuotes(text) {
      if (!text) return '';
      text = text.trim();
      if (!text) return '';
      var first = text.charAt(0);
      var last = text.charAt(text.length - 1);
      var pairs = {
        '"': '"',
        "'": "'",
        '«': '»',
        '“': '”',
        '„': '“',
        '‘': '’'
      };
      if (pairs[first] && last === pairs[first]) {
        return text.substring(1, text.length - 1).trim();
      }
      return text;
    }

    // --- Переключатель Table / Map -----------------------------------------
    $('#agreement-view-toggle button').on('click', function () {
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
        updateMapFromTable();
      }
    });

    // --- Сбор активных фильтров по признакам -------------------------------
    function getActiveFeatureFilters() {
      var filters = [];
      $('.feature-filter').each(function () {
        var val = $(this).val();
        if (!val) return;
        filters.push({
          paramId: $(this).data('param-id'),
          paramName: $(this).data('param-name') || '',
          value: val
        });
      });
      filters.sort(function (a, b) {
        if (a.paramName < b.paramName) return -1;
        if (a.paramName > b.paramName) return 1;
        return 0;
      });
      return filters;
    }

    // --- Применение фильтров к таблице -------------------------------------
    function applyAllFilters() {
      var featureFilters = getActiveFeatureFilters();

      // языки
      var selectedLangs = [];
      $('.language-checkbox:checked').each(function () {
        selectedLangs.push($(this).val());
      });
      var langAny = (!selectedLangs.length ||
                     selectedLangs.indexOf('') !== -1);
      selectedLangs = selectedLangs.filter(function (v) { return v !== ''; });

      // генетика
      var selectedGen = [];
      $('.genetic-checkbox:checked').each(function () {
        selectedGen.push($(this).val());
      });
      var genAny = (!selectedGen.length ||
                    selectedGen.indexOf('') !== -1);
      selectedGen = selectedGen.filter(function (v) { return v !== ''; });

      $('#agreement-table tbody tr').each(function () {
        var $row = $(this);
        var visible = true;

        // колонки 0 и 1: язык и генетика
        var langName = $.trim($row.find('td').eq(0).text());
        var genetic  = $.trim($row.find('td').eq(1).text());

        if (!langAny) {
          if ($.inArray(langName, selectedLangs) === -1) {
            visible = false;
          }
        }
        if (visible && !genAny) {
          if ($.inArray(genetic, selectedGen) === -1) {
            visible = false;
          }
        }

        // фильтры по признакам
        if (visible && featureFilters.length) {
          for (var i = 0; i < featureFilters.length; i++) {
            var f = featureFilters[i];
            var $cell = $row.find('td.feature-cell[data-param-id="' + f.paramId + '"]');
            var cellVal = $.trim($cell.text());
            if (!cellVal || cellVal !== f.value) {
              visible = false;
              break;
            }
          }
        }

        if (visible) {
          $row.show();
        } else {
          $row.hide();
        }
      });

      if ($('#agreement-map-view').is(':visible') && agreementMap) {
        updateMapFromTable();
      }
    }

    // --- Обработчики фильтров ----------------------------------------------
    $('.feature-filter').on('change', applyAllFilters);
    $('.language-checkbox').on('change', applyAllFilters);
    $('.genetic-checkbox').on('change', applyAllFilters);

    $('#language-filter-search').on('keyup', function () {
      var term = $(this).val().toLowerCase();
      $('#language-checkboxes label.checkbox').each(function () {
        var $lab = $(this);
        var txt = $lab.text().toLowerCase();
        var isAny = $lab.find('input').val() === '';
        if (!term || isAny || txt.indexOf(term) !== -1) {
          $lab.show();
        } else {
          $lab.hide();
        }
      });
    });

    $('#genetic-filter-search').on('keyup', function () {
      var term = $(this).val().toLowerCase();
      $('#genetic-checkboxes label.checkbox').each(function () {
        var $lab = $(this);
        var txt = $lab.text().toLowerCase();
        var isAny = $lab.find('input').val() === '';
        if (!term || isAny || txt.indexOf(term) !== -1) {
          $lab.show();
        } else {
          $lab.hide();
        }
      });
    });

    // Кнопка "Show full table"
    $('#show-full-table').on('click', function (e) {
      e.preventDefault();

      $('.feature-filter').val('');
      $('.language-checkbox, .genetic-checkbox').prop('checked', false);
      $('.language-checkbox[value=""], .genetic-checkbox[value=""]').prop('checked', true);

      $('#language-filter-search').val('');
      $('#genetic-filter-search').val('');
      $('#language-checkboxes label.checkbox').show();
      $('#genetic-checkboxes label.checkbox').show();

      $('#agreement-table tbody tr').show();

      if ($('#agreement-map-view').is(':visible') && agreementMap) {
        updateMapFromTable();
      }
    });

    // --- Модалка: описание признака ----------------------------------------
    $('.param-info').on('click', function (e) {
      e.preventDefault();
      var name = $(this).data('param-name');
      var desc = $(this).data('param-desc') || 'No description available.';
      $('#feature-modal .modal-header h3').text(name);
      $('#feature-modal .modal-body').html('<p>' + escapeHtml(desc) + '</p>');
      $('#feature-modal').modal('show');
    });

    // --- Модалка: примеры ---------------------------------------------------
    var featureExamplesUrl = "${request.route_url('feature_examples')}";

    $('#agreement-table').on('click', 'td.feature-cell', function () {
      var value = $.trim($(this).text());
      if (!value) return;

      var $cell = $(this);
      var paramId = $cell.data('param-id');
      var paramName = $cell.data('param-name');
      var $row = $cell.closest('tr');
      var langId = $row.data('lang-id');
      var langName = $.trim($row.find('td').eq(0).text());

      $('#feature-modal .modal-header h3').text(
        paramName + ' = ' + value + ' — ' + langName
      );
      $('#feature-modal .modal-body').html('<p><em>Loading examples…</em></p>');
      $('#feature-modal').modal('show');

      $.getJSON(featureExamplesUrl, {lang: langId, param: paramId}, function (data) {
        if (!data.ok || !data.examples || !data.examples.length) {
          $('#feature-modal .modal-body').html(
            '<p><em>No examples available for this cell.</em></p>'
          );
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
            html += '<p class="ig-translation">&#8216;'
                 + escapeHtml(trans)
                 + '&#8217;</p>';
          }

          if (ex.url) {
            html += '<p><a href="' + ex.url + '">View example page</a></p>';
          }

          html += '</div>';
          if (i < data.examples.length - 1) {
            html += '<hr/>';
          }
        });
        $('#feature-modal .modal-body').html(html);
      }).fail(function () {
        $('#feature-modal .modal-body').html(
          '<p><em>Error loading examples.</em></p>'
        );
      });
    });

    // -------- КАРТА ---------------------------------------------------------
    var agreementMap = null;
    var agreementMapLayer = null;
    var markerColors = [
      '#6baed6', '#9ecae1', '#74c476', '#a1d99b',
      '#fbb4b9', '#fdd0a2', '#bcbddc', '#c7e9c0', '#f2f0f7'
    ];
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
      return L.divIcon({
        className: 'agreement-map-marker',
        html: html,
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });
    }

    function renderLegend(categories) {
      var $legend = $('#agreement-map-legend');
      if (!categories.length) {
        $legend.html('<p class="muted"><em>No languages to show on the map for the current filters.</em></p>');
        return;
      }
      var total = 0;
      $.each(categories, function (i, cat) { total += cat.count; });

      var html = '<strong>Legend</strong> ' +
                 '<span class="muted">(languages on map: ' + total + ')</span>' +
                 '<ul class="unstyled">';
      $.each(categories, function (i, cat) {
        var color = cat.style.color;
        var shape = cat.style.shape;
        var symbol = shapeChars[shape] || '●';
        html += '<li class="legend-item">' +
                '<span class="legend-symbol" style="color:' + color + ';">' + symbol + '</span>' +
                escapeHtml(cat.label || 'All languages') + ' — ' +
                '<span class="badge">' + cat.count + '</span>' +
                '</li>';
      });
      html += '</ul>';
      $legend.html(html);
    }

    function rowsForMap() {
      var useAllRows = $('#map-include-other-values').is(':checked');
      if (useAllRows) {
        return $('#agreement-table tbody tr');
      } else {
        return $('#agreement-table tbody tr:visible');
      }
    }

    function updateMapFromTable() {
      if (!agreementMap || !agreementMapLayer) return;

      agreementMapLayer.clearLayers();
      var activeFilters = getActiveFeatureFilters();
      var categoriesByKey = {};
      var categories = [];

      var $rows = rowsForMap();

      $rows.each(function () {
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
            var val = $.trim($cell.text()) || 'n/a';
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
          var style = getCategoryStyle(idx);
          categoriesByKey[key] = { key: key, label: label, count: 0, style: style };
          categories.push(categoriesByKey[key]);
        }

        var cat = categoriesByKey[key];
        cat.count++;

        var icon = makeIconForStyle(cat.style);
        if (!icon) return;

        var popup = '<strong>' + escapeHtml(langName) + '</strong>';
        if (label) popup += '<br/>' + escapeHtml(label);

        var marker = L.marker([lat, lon], {icon: icon}).bindPopup(popup);
        agreementMapLayer.addLayer(marker);
      });

      if (agreementMapLayer.getLayers().length) {
        try {
          agreementMap.fitBounds(agreementMapLayer.getBounds().pad(0.1));
        } catch (e) {}
      }

      renderLegend(categories);
    }

    function ensureMapInitialized() {
      if (typeof L === 'undefined') {
        $('#agreement-map').html(
          '<p class="text-error"><em>Map library (Leaflet) is not available.</em></p>'
        );
        return;
      }

      if (!agreementMap) {
        agreementMap = L.map('agreement-map', {attributionControl: false});
        agreementMapLayer = L.layerGroup().addTo(agreementMap);

        L.tileLayer(
          'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
          {maxZoom: 16}
        ).addTo(agreementMap);

        L.control.attribution({
          position: 'bottomright',
          prefix: ''
        }).addTo(agreementMap).addAttribution(
          'Tiles © Esri — Esri, DeLorme, NAVTEQ'
        );

        agreementMap.setView([20, 0], 2);
      }

      setTimeout(function () {
        agreementMap.invalidateSize();
        updateMapFromTable();
      }, 0);
    }

    $('#map-include-other-values').on('change', function () {
      if ($('#agreement-map-view').is(':visible') && agreementMap) {
        updateMapFromTable();
      }
    });

    // первоначальное состояние
    applyAllFilters();
  });
</script>

