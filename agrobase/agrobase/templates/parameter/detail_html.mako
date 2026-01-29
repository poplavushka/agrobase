<%inherit file="../agrobase.mako"/>
<%! active_menu_item = "parameters" %>

<%
  import json
  from sqlalchemy import func
  from clld.db.meta import DBSession
  from clld.db.models import common

  def value_label(v):
      if v.domainelement:
          return (v.domainelement.name or '').strip()
      return (v.name or '').strip()

  # какие значения вообще встречаются (чтобы понять yes/no)
  raw_vals = {
      (x or '').strip().lower()
      for (x,) in (
          DBSession.query(func.lower(func.coalesce(common.DomainElement.name, common.Value.name)))
          .join(common.Value.valueset)
          .outerjoin(common.Value.domainelement)
          .filter(common.ValueSet.parameter_pk == ctx.pk)
          .distinct()
          .all()
      )
  }
  raw_vals = {v for v in raw_vals if v}
  is_yesno = bool(raw_vals) and raw_vals.issubset({'yes', 'no'})

  # точки для карты: 1 точка на язык
  seen = set()
  points = []

  vs_q = (
      DBSession.query(common.ValueSet)
      .join(common.Language)
      .filter(common.ValueSet.parameter_pk == ctx.pk)
      .order_by(common.Language.name)
      .all()
  )

  for vs in vs_q:
      lang = vs.language
      if not lang or lang.id in seen:
          continue

      # значения для этого языка и параметра
      labs = []
      seen_l = set()
      for v in vs.values:
          lab = value_label(v)
          if lab and lab not in seen_l:
              seen_l.add(lab)
              labs.append(lab)
      vstr = ', '.join(labs)
      vlow = vstr.strip().lower()

      if is_yesno and vlow != 'yes':
          continue

      lat = getattr(lang, 'latitude', None)
      lon = getattr(lang, 'longitude', None)
      jdl = lang.jsondata or {}
      if lat in (None, ''):
          lat = jdl.get('latitude') or jdl.get('Latitude') or None
      if lon in (None, ''):
          lon = jdl.get('longitude') or jdl.get('Longitude') or None

      try:
          lat_f = float(lat)
          lon_f = float(lon)
      except Exception:
          continue

      seen.add(lang.id)
      points.append(dict(
          id=lang.id,
          name=lang.name,
          lat=lat_f,
          lon=lon_f,
          url=request.route_url('language', id=lang.id),
          value=(vstr or '—'),
      ))

  points_json = json.dumps(points, ensure_ascii=False)

  jd = ctx.jsondata or {}
  author = (jd.get('author') or jd.get('compiled') or jd.get('compiled_by') or '').strip()
  published = (jd.get('published') or jd.get('date') or '').strip()
%>

<div class="agro-feature-page">
  <h1 class="agro-feature-title">${ctx.name}</h1>

  <div class="agro-feature-meta">
    % if author:
      <div><span class="agro-meta-label">AUTHOR</span> ${author}</div>
    % endif
    % if published:
      <div><span class="agro-meta-label">PUBLISHED</span> ${published}</div>
    % endif
  </div>

  <div class="agro-feature-text">
    % if ctx.description:
      ${ctx.description | n}
    % else:
      <em>Description coming soon.</em>
    % endif
  </div>

  <h2 class="agro-section-title">Feature Map</h2>

  <ul class="nav nav-tabs" id="feature-tabs">
    <li class="active"><a href="#tab-map" data-toggle="tab">Map</a></li>
    <li><a href="#tab-data" data-toggle="tab">Data</a></li>
  </ul>

  <div class="tab-content">
    <div class="tab-pane active" id="tab-map">
      <div id="agro-feature-map" style="height:480px;border:1px solid #ddd;border-radius:4px;"></div>
      <div id="agro-feature-legend" class="well well-small" style="margin-top:10px;">
        <div id="agro-feature-count" class="muted"></div>
        <div id="agro-feature-legend-items" class="muted" style="margin-top:6px;"></div>
      </div>
    </div>

    <div class="tab-pane" id="tab-data">
      ${request.get_datatable('values', h.models.Value, parameter=ctx).render()}
    </div>
  </div>
</div>

<div id="example-modal" class="modal hide fade">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal">×</button>
    <h3>Examples</h3>
  </div>
  <div class="modal-body">
    <p><em>Loading…</em></p>
  </div>
</div>

<style>
  .agro-feature-page { max-width: 980px; margin: 0 auto; }
  .agro-feature-title { font-size: 44px; line-height: 1.1; margin-top: 10px; margin-bottom: 10px; }
  .agro-feature-meta { display: flex; gap: 50px; margin: 10px 0 20px; color: #222; }
  .agro-meta-label { display: inline-block; width: 90px; color: #777; font-size: 12px; letter-spacing: 0.08em; }
  .agro-feature-text { font-size: 16px; line-height: 1.6; margin-bottom: 25px; }
  .agro-section-title { margin-top: 25px; margin-bottom: 10px; font-size: 34px; line-height: 1.2; }
</style>

<script type="text/javascript">
  $(function () {
    function escapeHtml(text) {
      return $('<div/>').text(text || '').html();
    }

    // -------------------- Examples ("more") --------------------
    var featureExamplesUrl = "${request.route_url('feature_examples')}";

    $(document).on('click', '.value-example', function (e) {
      e.preventDefault();

      var $btn = $(this);
      var langId = $btn.data('lang-id');
      var langName = $btn.data('lang-name') || '';
      var paramId = $btn.data('param-id');

      $('#example-modal .modal-header h3').text('Examples — ' + langName);
      $('#example-modal .modal-body').html('<p><em>Loading…</em></p>');
      $('#example-modal').modal('show');

      $.getJSON(featureExamplesUrl, {lang: langId, param: paramId}, function (data) {
        if (!data.ok || !data.examples || !data.examples.length) {
          $('#example-modal .modal-body').html('<p><em>No examples available.</em></p>');
          return;
        }

        var html = '';
        $.each(data.examples, function (i, ex) {
          html += '<div class="example">';
          if (ex.primary) html += '<pre>' + escapeHtml(ex.primary) + '</pre>';
          if (ex.gloss)   html += '<pre>' + escapeHtml(ex.gloss)   + '</pre>';
          if (ex.translation) html += '<p class="ig-translation">&#8216;' + escapeHtml(ex.translation) + '&#8217;</p>';
          if (ex.url) html += '<p><a href="' + ex.url + '">View example page</a></p>';
          html += '</div>';
          if (i < data.examples.length - 1) html += '<hr/>';
        });

        $('#example-modal .modal-body').html(html);
      }).fail(function () {
        $('#example-modal .modal-body').html('<p><em>Error loading examples.</em></p>');
      });
    });

    // -------------------- Map --------------------
    var points = ${points_json | n};

    if (typeof L === 'undefined') {
      $('#agro-feature-map').html('<p class="text-error" style="padding:10px;"><em>Leaflet is not available.</em></p>');
      return;
    }

    var map = L.map('agro-feature-map', { attributionControl: false });
    var layer = L.layerGroup().addTo(map);

    L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      { maxZoom: 16 }
    ).addTo(map);

    L.control.attribution({ position: 'bottomright', prefix: '' })
      .addTo(map)
      .addAttribution('Tiles © Esri — Esri, DeLorme, NAVTEQ');

    var palette = ['#6baed6', '#74c476', '#fbb4b9', '#9ecae1', '#a1d99b', '#fdd0a2'];
    var colorByValue = {};
    var valueCounts = {};

    function getColor(val) {
      val = (val || '—').toString();
      if (!colorByValue[val]) {
        var idx = Object.keys(colorByValue).length % palette.length;
        colorByValue[val] = palette[idx];
      }
      return colorByValue[val];
    }

    var bounds = [];
    var byLangId = {};

    $.each(points, function (_, p) {
      var val = p.value || '—';
      valueCounts[val] = (valueCounts[val] || 0) + 1;

      var color = getColor(val);
      var marker = L.circleMarker([p.lat, p.lon], {
        radius: 6, weight: 1, opacity: 0.9, fillOpacity: 0.9,
        color: color, fillColor: color
      });

      marker.bindTooltip(p.name, { direction: 'top', offset: [0, -4], opacity: 0.9 });
      marker.bindPopup(
        '<strong><a href="' + p.url + '">' + escapeHtml(p.name) + '</a></strong>' +
        '<br/><span style="color:#666;">' + escapeHtml(val) + '</span>'
      );

      layer.addLayer(marker);
      bounds.push([p.lat, p.lon]);
      byLangId[p.id] = marker;
    });

    $('#agro-feature-count').text(points.length + ' languages shown on the map');

    // легенда
    var leg = '';
    $.each(Object.keys(valueCounts).sort(), function (_, k) {
      var c = getColor(k);
      leg += '<div><span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:' + c + ';margin-right:6px;"></span>'
          + escapeHtml(k) + ' (' + valueCounts[k] + ')</div>';
    });
    $('#agro-feature-legend-items').html(leg);

    if (bounds.length) map.fitBounds(bounds, { padding: [20, 20] });
    else map.setView([20, 0], 2);

    // табы (bootstrap2/3)
    $('#feature-tabs a[href="#tab-map"]').on('shown shown.bs.tab', function () {
      setTimeout(function () { map.invalidateSize(); }, 0);
    });

    // -------------------- Show on the map (из таблицы) --------------------
    $(document).on('click', '.show-on-map', function (e) {
      e.preventDefault();
      $('#feature-tabs a[href="#tab-map"]').tab('show');

      var $btn = $(this);
      var id = $btn.data('lang-id');
      var lat = parseFloat($btn.data('lat'));
      var lon = parseFloat($btn.data('lon'));

      if (!isNaN(lat) && !isNaN(lon)) {
        map.setView([lat, lon], Math.max(map.getZoom(), 7));
      }

      // если маркер есть — откроем попап
      if (id && byLangId[id]) {
        byLangId[id].openPopup();
      }
    });
  });
</script>
