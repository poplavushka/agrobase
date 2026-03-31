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
  .agro-narrow-table .dataTables_wrapper {
    margin-top: 10px;
  }

  .agro-narrow-table table.dataTable tbody td:nth-child(2) {
    font-size: 20px;
    line-height: 1.25;
  }

  .agro-narrow-table table.dataTable tbody td:nth-child(2) a {
    font-size: inherit;
    font-weight: 500;
    line-height: inherit;
  }
</style>
