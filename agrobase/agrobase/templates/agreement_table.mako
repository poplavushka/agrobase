<%inherit file="agrobase.mako"/>

<%block name="title">Agreement & metadata table</%block>

<h1>Agreement & metadata table</h1>

<p class="lead">
    Languages × agreement features × language metadata.
</p>

## чекбоксы: какие группы признаков вообще показывать как колонки
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
%>

<div class="well">
  <h3>Filter by features</h3>
  <p>
    Choose values for any subset of features. Columns with <strong>Any</strong> are ignored.
  </p>

  ## --- Фильтр по языку и генетике (чекбоксы + Any + поиск) ---
  <fieldset style="margin-bottom: 1em;">
    <legend>Language / genetic</legend>

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

  ## --- Фильтры по metadata ---
  % if show_meta and meta_params:
    <fieldset style="margin-bottom: 1em;">
      <legend>Language metadata</legend>
      % for p in meta_params:
        <% col_index = col_index_by_pk.get(p.pk) %>
        % if col_index is not None:
          <label style="display: block; margin-bottom: 4px;">
            <span class="param-info"
                  data-param-name="${p.name}"
                  data-param-desc="${p.description or ''}">
              ${p.name}
            </span>:
            <select class="feature-filter" data-column="${col_index}">
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
  % endif

  ## --- Фильтры по agreement (иерархически) ---
  % if show_agr and agr_hyperparams:
    <fieldset>
      <legend>Agreement features</legend>

      % for hp in agr_hyperparams:
        <details style="margin-bottom: 0.5em;">
          <summary style="cursor: pointer; font-weight: bold;">
            <span class="param-info"
                  data-param-name="${hp.name}"
                  data-param-desc="${hp.description or ''}">
              ${hp.name}
            </span>
          </summary>

          <% col_hp = col_index_by_pk.get(hp.pk) %>
          % if col_hp is not None:
            <label style="display: block; margin: 4px 0;">
              <span class="param-info"
                    data-param-name="${hp.name}"
                    data-param-desc="${hp.description or ''}">
                ${hp.name}
              </span>:
              <select class="feature-filter" data-column="${col_hp}">
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
            <% col_index = col_index_by_pk.get(p.pk) %>
            % if col_index is not None:
              <label style="display: block; margin: 4px 0 4px 1.5em;">
                <span class="param-info"
                      data-param-name="${p.name}"
                      data-param-desc="${p.description or ''}">
                  ${p.name}
                </span>:
                <select class="feature-filter" data-column="${col_index}">
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
</div>

<div style="margin-bottom: 0.5em;">
  <button id="show-full-table" class="btn btn-small">
    Show full table
  </button>
</div>

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
    <tr data-lang-id="${lang.id}">
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

## Модальное окно для описаний признаков и примеров
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
    white-space: pre-wrap; /* переносить строки, но сохранять пробелы */
  }
  .ig-translation {
    margin-top: 0.25em;
  }

  /* Кликабельные названия признаков (показывают описание) */
  .param-info {
    cursor: help;
    border-bottom: 1px dotted #999;
    color: #444;
  }
  .param-info:hover {
    color: #0056b3;
  }

  /* Кликабельные ячейки со значением признака (открывают примеры) */
  #agreement-table td.feature-cell {
    cursor: pointer;
    text-decoration: underline;
    text-decoration-style: dotted;
    text-decoration-thickness: 1px;
  }

  /* Подсветка только ячейки, а не всей строки */
  #agreement-table td.feature-cell:hover {
    background-color: #fff8dc !important; /* перебивает .table-striped */
  }
</style>



<script type="text/javascript">
  $(function () {
    var table = $('#agreement-table').DataTable({
      bPaginate: true,
      bLengthChange: true,
      bFilter: true,
      bSort: true
    });

    // helper: экранировать HTML
    function escapeHtml(text) {
      return $('<div/>').text(text || '').html();
    }

    // helper: обрезать внешние кавычки, если они есть
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

    // --- Фильтры по значениям признаков + скрытие лишних колонок ---
    $('.feature-filter').on('change', function () {
      // при любом изменении пересчитываем ВСЕ feature-фильтры
      $('.feature-filter').each(function () {
        var colIndex = parseInt($(this).data('column'), 10);
        var val = $(this).val();

        if (val) {
          // фильтруем по точному совпадению значения
          var escaped = $.fn.dataTable.util.escapeRegex(val);
          table.column(colIndex).search('^' + escaped + '$', true, false);
          // колонка с этим признаком должна быть видимой
          table.column(colIndex).visible(true);
        } else {
          // Any: снимаем фильтр и прячем колонку
          table.column(colIndex).search('');
          table.column(colIndex).visible(false);
        }
      });

      table.draw();
    });

    // --- Фильтр по языку (чекбоксы + Any) ---
    function applyLanguageFilter() {
      var colIndex = 0; // колонка Language
      var selected = [];

      $('.language-checkbox:checked').each(function () {
        selected.push($(this).val());
      });

      // только Any или ничего → фильтр выключен
      if (!selected.length || (selected.length === 1 && selected[0] === "")) {
        table.column(colIndex).search('');
      } else {
        // игнорируем Any, если вместе с реальными значениями
        selected = selected.filter(function (v) { return v !== ""; });
        var escaped = $.map(selected, function (v) {
          return $.fn.dataTable.util.escapeRegex(v);
        });
        var pattern = '^(' + escaped.join('|') + ')$';
        table.column(colIndex).search(pattern, true, false);
      }
      table.draw();
    }

    $('.language-checkbox').on('change', applyLanguageFilter);

    // поиск по списку языков
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

    // --- Фильтр по генетике (чекбоксы + Any) ---
    function applyGeneticFilter() {
      var colIndex = 1; // колонка Genetic
      var selected = [];

      $('.genetic-checkbox:checked').each(function () {
        selected.push($(this).val());
      });

      if (!selected.length || (selected.length === 1 && selected[0] === "")) {
        table.column(colIndex).search('');
      } else {
        selected = selected.filter(function (v) { return v !== ""; });
        var escaped = $.map(selected, function (v) {
          return $.fn.dataTable.util.escapeRegex(v);
        });
        var pattern = '^(' + escaped.join('|') + ')$';
        table.column(colIndex).search(pattern, true, false);
      }
      table.draw();
    }

    $('.genetic-checkbox').on('change', applyGeneticFilter);

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

    // --- Кнопка "Show full table": сброс всех фильтров ---
    $('#show-full-table').on('click', function (e) {
      e.preventDefault();

      // 1. Сбросить feature-фильтры и показать все их колонки
      $('.feature-filter').each(function () {
        var $sel = $(this);
        $sel.val('');
        var colIndex = parseInt($sel.data('column'), 10);
        table.column(colIndex).search('');
        table.column(colIndex).visible(true);
      });

      // 2. Сбросить язык/генетику: оставить только Any
      $('.language-checkbox, .genetic-checkbox').prop('checked', false);
      $('.language-checkbox[value=""], .genetic-checkbox[value=""]').prop('checked', true);

      $('#language-filter-search').val('');
      $('#genetic-filter-search').val('');

      $('#language-checkboxes label.checkbox').show();
      $('#genetic-checkboxes label.checkbox').show();

      // 3. Очистить поиски DataTables и показать все колонки
      table.search('');
      table.columns().search('');
      table.columns().visible(true);

      table.draw();
    });

    // --- Модалка для описаний признаков (клик по имени признака) ---
    $('.param-info').on('click', function (e) {
      e.preventDefault();
      var name = $(this).data('param-name');
      var desc = $(this).data('param-desc') || 'No description available.';
      $('#feature-modal .modal-header h3').text(name);
      $('#feature-modal .modal-body').html('<p>' + escapeHtml(desc) + '</p>');
      $('#feature-modal').modal('show');
    });

    // --- Модалка с примерами (клик по ячейке со значением признака) ---
    var featureExamplesUrl = "${request.route_url('feature_examples')}";

    $('#agreement-table').on('click', 'td.feature-cell', function () {
      var value = $.trim($(this).text());
      if (!value) {
        return; // пустая ячейка
      }
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
            if (primary) {
              html += '<pre>' + escapeHtml(primary) + '</pre>';
            }
            if (gloss) {
              html += '<pre>' + escapeHtml(gloss) + '</pre>';
            }
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
  });
</script>
