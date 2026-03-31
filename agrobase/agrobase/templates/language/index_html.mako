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

    var geojsonCandidates = ["${request.route_url('languages')}.geojson"];

    var langCount = 0;

    function drawLanguages(data) {
      if (!data || !data.features) {
        map.setView([20, 0], 2);
        $('#languages-count').text('0 languages in our database.');
        return;
      }

      var bounds = [];

      $.each(data.features, function (i, feature) {
        if (!feature.geometry) return;

        var coords = feature.geometry.coordinates;
        if (feature.geometry.type === 'Point') {
          coords = [coords];
        } else if (feature.geometry.type !== 'MultiPoint') {
          return;
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

          var props = feature.properties || {};
          var name = props.name || props.Name || '';
          var id = feature.id || props.id || props.pk || '';

          // ссылка на страницу языка
          var url = props.url || "${request.route_url('languages')}/" + encodeURIComponent(id);

          if (name || id) {
            var label = name || id;
            marker.bindPopup('<a href="' + url + '"><strong>' + label + '</strong></a>');
          }

          markersLayer.addLayer(marker);
          bounds.push([lat, lon]);
          langCount += 1;
        });
      });

      if (bounds.length) {
        map.fitBounds(bounds, {padding: [20, 20]});
      } else {
        map.setView([20, 0], 2);
      }

      $('#languages-count').text(
        langCount + ' languages already in our database'
      );
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
