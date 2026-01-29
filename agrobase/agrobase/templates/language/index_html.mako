<%inherit file="../agrobase.mako"/>

<h2>Languages</h2>

<div id="languages-map-wrapper" style="margin-top: 1.5em; margin-bottom: 1.5em;">
  <div id="languages-map"
       style="height: 420px; border: 1px solid #ddd; border-radius: 4px; width: 100%;">
  </div>
</div>

<p id="languages-count"
   style="margin-top: 0.7em; font-weight: bold; font-size: 15px; color: #000;">
</p>

${request.get_datatable('languages', h.models.Language).render()}

<script type="text/javascript">
  $(function () {
    var mapDiv = $('#languages-map');
    if (!mapDiv.length || typeof L === 'undefined') {
      return;
    }

    var map = L.map('languages-map', { attributionControl: false });
    var markersLayer = L.layerGroup().addTo(map);

    // серая подложка Esri, как на главной
    L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      { maxZoom: 16 }
    ).addTo(map);

    L.control.attribution({ position: 'bottomright', prefix: '' })
      .addTo(map)
      .addAttribution('Tiles © Esri — Esri, DeLorme, NAVTEQ');

    var palette = ['#6baed6', '#74c476', '#fbb4b9', '#9ecae1', '#a1d99b', '#fdd0a2'];

    // Правильный шаблон URL на страницу языка: /languages/<id>
    var languageUrlTemplate = "${request.route_url('language', id='__ID__')}";

    var geojsonCandidates = [
      "${request.route_url('languages')}?_format=geojson",
      "${request.route_url('languages')}?format=geojson",
      "${request.route_url('languages')}.geojson"
    ];

    function escapeHtml(text) {
      return $('<div/>').text(text || '').html();
    }

    function drawLanguages(data) {
      var $count = $('#languages-count');

      if (!data || !data.features || !data.features.length) {
        map.setView([20, 0], 2);
        $count.text('0 languages in our database.');
        return;
      }

      var bounds = [];
      var langCount = 0;

      $.each(data.features, function (i, feature) {
        if (!feature.geometry) return;

        var geomType = feature.geometry.type;
        var coords = feature.geometry.coordinates;

        // поддерживаем Point и MultiPoint, как на главной
        if (geomType === 'Point') {
          coords = [coords];
        } else if (geomType !== 'MultiPoint') {
          return;
        }

        var props = feature.properties || {};
        var name = props.name || props.Name || '';

        // ВАЖНО: id часто в feature.id, а не в props
        var id = feature.id || props.id || props.pk || '';

        // URL: если geojson отдаёт props.url — используем его.
        // иначе строим по route_url('language', ...)
        var url = null;
        if (props.url) {
          url = props.url;
        } else if (id) {
          url = languageUrlTemplate.replace('__ID__', encodeURIComponent(id));
        }

        $.each(coords, function (_, c) {
          var lon = c[0], lat = c[1];
          if (lat == null || lon == null || isNaN(lat) || isNaN(lon)) return;

          var color = palette[i % palette.length];

          var marker = L.circleMarker([lat, lon], {
            radius: 6,
            weight: 1,
            opacity: 0.9,
            fillOpacity: 0.9,
            color: color,
            fillColor: color
          });

          // tooltip при наведении
          if (name) {
            marker.bindTooltip(name, {
              direction: 'top',
              offset: [0, -4],
              opacity: 0.9
            });
          }

          // popup: делаем ссылку ТОЛЬКО если url есть
          var label = name || id;
          if (label) {
            var popup = '';
            if (url) {
              popup = '<strong><a href="' + url + '">' + escapeHtml(label) + '</a></strong>';
            } else {
              popup = '<strong>' + escapeHtml(label) + '</strong>';
            }
            if (id) {
              popup += '<br/><span style="color:#666;">' + escapeHtml(id) + '</span>';
            }
            marker.bindPopup(popup);
          }

          markersLayer.addLayer(marker);
          bounds.push([lat, lon]);
          langCount += 1;
        });
      });

      if (bounds.length) {
        map.fitBounds(bounds, { padding: [20, 20] });
      } else {
        map.setView([20, 0], 2);
      }

      $count.text(langCount + ' languages already in our database');
    }

    function loadGeoJSON(urls) {
      if (!urls.length) {
        map.setView([20, 0], 2);
        $('#languages-count').text('0 languages in our database.');
        return;
      }
      var url = urls.shift();
      $.getJSON(url, function (data) {
        drawLanguages(data);
      }).fail(function () {
        loadGeoJSON(urls);
      });
    }

    loadGeoJSON(geojsonCandidates);
  });
</script>
