<%inherit file="../agrobase.mako"/>

<%def name="sidebar()">
    ## Пустой сайдбар — правая колонка будет пустой.
</%def>
<hr/>
</p>
<h3>Welcome to the AGRoBase</h3>

<p class="agro-lead">
  An online database on Agreement properties of world’s languages.
</p>

<h3>How to use AGRoBase</h3>

<p class="agro-text">
  The database contains grammatical information on agreement features in a sample of world’s languages.
  This page <a href="${request.route_url('parameters')}">contains the list of agreement features</a>.
  The list of the languages can be found <a href="${request.route_url('languages')}">here</a>.
  Here you can <a href="${request.route_url('contact')}">leave your feedback</a> on the project.
</p>


<div id="home-language-map-wrapper" class="home-language-map-wrapper">
  <h3>Languages in AGRobase</h3>
  <div id="home-language-map" class="home-language-map"></div>
  <div id="home-language-map-count" class="home-language-map-count"></div>
</div>

<script type="text/javascript">
  $(function () {
    var mapDiv = $('#home-language-map');
    if (!mapDiv.length || typeof L === 'undefined') {
      return;
    }

    // --- создаём карту с серой подложкой Esri ---
    var homeMap = L.map('home-language-map', {
      attributionControl: false
    });
    var markersLayer = L.layerGroup().addTo(homeMap);

    L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
      { maxZoom: 16 }
    ).addTo(homeMap);

    L.control.attribution({
      position: 'bottomright',
      prefix: ''
    }).addTo(homeMap).addAttribution(
      'Tiles © Esri — Esri, DeLorme, NAVTEQ'
    );

    // Мягкая пастель для точек
    var palette = ['#6baed6', '#74c476', '#fbb4b9', '#9ecae1', '#a1d99b', '#fdd0a2'];

    // Шаблон URL для страницы языка: /language/<id>
    var languageUrlTemplate = "${request.route_url('language', id='__ID__')}";

    // Кандидаты на URL GeoJSON со всеми языками
    var geojsonCandidates = [
      "${request.route_url('languages')}?_format=geojson",
      "${request.route_url('languages')}?format=geojson",
      "${request.route_url('languages')}.geojson"
    ];

    function drawLanguages(data) {
      var $count = $('#home-language-map-count');

      if (!data || !data.features || !data.features.length) {
        homeMap.setView([20, 0], 2);
        $count.text('No languages shown.');
        return;
      }

      var bounds = [];
      var n = 0;

      $.each(data.features, function (i, feature) {
        if (!feature.geometry) return;

        var geomType = feature.geometry.type;
        var coords = feature.geometry.coordinates;

        if (geomType === 'Point') {
          coords = [coords];   // приводим к списку
        } else if (geomType === 'MultiPoint') {
          // уже список
        } else {
          return; // игнорируем всё, что не точки
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
          var url = null;

          if (props.url) {
            url = props.url;
          } else if (id) {
            url = languageUrlTemplate.replace('__ID__', encodeURIComponent(id));
          }

          // тултип при наведении
          if (name) {
            marker.bindTooltip(name, {
              direction: 'top',
              offset: [0, -4],
              opacity: 0.9
            });
          }

          // попап при клике: имя (ссылка) + id
          var popup = '';
          if (url && name) {
            popup += '<strong><a href="' + url + '">' + name + '</a></strong>';
          } else if (name) {
            popup += '<strong>' + name + '</strong>';
          }
          if (id) {
            popup += '<br/><span style="color:#666;">' + id + '</span>';
          }
          if (popup) {
            marker.bindPopup(popup);
          }

          markersLayer.addLayer(marker);
          bounds.push([lat, lon]);
          n += 1;
        });
      });

      if (bounds.length) {
        homeMap.fitBounds(bounds, { padding: [20, 20] });
      } else {
        homeMap.setView([20, 0], 2);
      }

      // подпись под картой
      $count.text(n + ' languages already in our database');
    }

    function loadGeoJSON(urls) {
      if (!urls.length) {
        homeMap.setView([20, 0], 2);
        $('#home-language-map-count').text('No languages shown.');
        return;
      }
      var url = urls.shift();
      $.getJSON(url, function (data) {
        drawLanguages(data);
      }).fail(function () {
        loadGeoJSON(urls);
      });
    }

    // старт
    loadGeoJSON(geojsonCandidates);
  });
</script>
