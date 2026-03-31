<%inherit file="../${context.get('request').registry.settings.get('clld.app_template', 'app.mako')}"/>
<%namespace name="util" file="../util.mako"/>
<%! active_menu_item = "languages" %>
<%block name="title">${_('Language')} ${ctx.name}</%block>

<h2>${_('Language')} ${ctx.name}</h2>

${request.get_datatable('values', h.models.Value, language=ctx).render()}

<style>
  #ValuesDataTable th.example-col,
  #ValuesDataTable th:nth-child(3),
  #ValuesDataTable td.example-col {
    min-width: 420px;
    max-width: 620px;
    white-space: normal;
    vertical-align: top;
  }

  #ValuesDataTable td.example-col .example-line {
    font-family: "Courier New", monospace;
    white-space: pre-wrap;
    line-height: 1.35;
  }

  #ValuesDataTable td.example-col .example-translation {
    margin-top: 4px;
    color: #333;
  }
</style>

<script type="text/javascript">
  $(window).on('load', function () {
    function applyEsriBaseLayer(attempt) {
      if (typeof CLLD === 'undefined' || typeof L === 'undefined' || !CLLD.mapGetMap) {
        if (attempt < 40) setTimeout(function () { applyEsriBaseLayer(attempt + 1); }, 100);
        return;
      }

      var clldMap = CLLD.mapGetMap('map');
      if (!clldMap || !clldMap.map) {
        if (attempt < 40) setTimeout(function () { applyEsriBaseLayer(attempt + 1); }, 100);
        return;
      }

      var map = clldMap.map;
      var baseLayers = [];
      map.eachLayer(function (layer) {
        if (layer instanceof L.TileLayer) {
          baseLayers.push(layer);
        }
      });

      $.each(baseLayers, function (_, layer) {
        map.removeLayer(layer);
      });

      L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
        { maxZoom: 16 }
      ).addTo(map);

      if (map.attributionControl) {
        map.attributionControl.setPrefix('');
        map.attributionControl.addAttribution('Tiles © Esri — Esri, DeLorme, NAVTEQ');
      }
    }

    applyEsriBaseLayer(0);
  });
</script>

<%def name="sidebar()">
    ${util.language_meta()}
</%def>
