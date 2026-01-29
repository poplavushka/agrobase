<%inherit file="../agrobase.mako"/>
<%! active_menu_item = "parameters" %>

<h2 style="text-align:center; margin-top: 10px;">Features</h2>

<div class="agro-narrow-table">
  ${request.get_datatable('parameters', h.models.Parameter).render()}
</div>

<style>
  .agro-narrow-table {
    max-width: 980px;
    margin: 0 auto;
  }
  /* чуть приятнее как на Rutul */
  .agro-narrow-table .dataTables_wrapper {
    margin-top: 10px;
  }
</style>

<style>
  .agro-narrow-table {
    max-width: 980px;
    margin: 0 auto;
  }

  /* крупнее название параметра */
  .agro-narrow-table td.agro-param-name a {
    font-size: 18px;
    font-weight: 400;
    line-height: 1.25;
  }
</style>

