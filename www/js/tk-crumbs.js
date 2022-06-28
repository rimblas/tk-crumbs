var tk = tk || {};


(function(tk, $, undefined) {

var _CRUMB_DONE = "fa-check-square-o",
    _CRUMB_NOT_DONE = "fa-square-o"

tk.crumbs = {

  init: function() {
    apex.jQuery( "div.crumbs .removeCrumb" ).on( "click", function(e) {
      tk.crumbs.removeCrumb(this.dataset.crumbid);
      e.preventDefault();
    });
    apex.jQuery( "div.crumbs .checkCrumb" ).on( "click", function(e) {
      tk.crumbs.completeCrumb(this.dataset.crumbid);
      e.preventDefault();
    });
    apex.jQuery( "#tkAddCrumb" ).on( "click", function(e) {
      tk.crumbs.addCrumb(this.dataset.crumbtype, this.dataset.crumbid);
    });
  },


  addCrumb: function(pEntity, pID) {

      apex.server.process(
          'ADD_CRUMB', {
              x01: pEntity,
              x02: pID
          }, 
          {
              success: function(data) {
                  $("#tkAddCrumb span.t-Icon").removeClass("fa-bookmark-o").addClass("fa-bookmark");
                  $('.crumbs ul').append('<li class="active" data-crumbid="' + pID + '"><a href="#0" class="active">ID ' + pID + '<br></a></li>');
                  $('.crumbs ul').show(); // in case it's the first one and it was hidden
                  apex.message.showPageSuccess("Crumb added.");
                  apex.jQuery( "#tkAddCrumb" ).off( "click");  // prevent multi-add
              }
          }
      );
  },

  removeCrumb: function(pID) {

      apex.server.process(
          'REMOVE_CRUMB', {
              x01: pID
          }, 
          {
              loadingIndicator: $('.crumbs li[data-crumbid="' + pID + '"]'),
              success: function(data) {
                  $('.crumbs li[data-crumbid="' + pID + '"]').remove();
                  $("div.crumbs").trigger("tkRemoveCrumb", {crumbid: pID});
              }
          }
      );
  },

  completeCrumb: function(pID) {

      apex.server.process(
          'COMPLETE_CRUMB', {
              x01: pID
          }, 
          {
              loadingIndicator: $('.crumbs li[data-crumbid="' + pID + '"]'),
              success: function(data) {
                  var $el = $('.crumbs li[data-crumbid="' + pID + '"]');
                  $el.toggleClass("done");
                  $el.find(".checkCrumb i").removeClass().addClass("fa");
                  if ($el.hasClass("done")) {
                    $el.find(".checkCrumb i").addClass(_CRUMB_DONE);
                  }
                  else {
                    $el.find(".checkCrumb i").addClass(_CRUMB_NOT_DONE);
                  }
                  $("div.crumbs").trigger("tkCompleteCrumb", {crumbid: pID});
              }
          }
      );
  },



  crumbInfo: async function(pEntityType) {

    return  apex.server.process(
         'CRUMB_INFO', {
             x01: pEntityType
         },
         {
             success: function(data) {
                if (!data.success){
                 console.error(data.message);
                }
             }
         }
     );
  },

  /**
   * Used when adding multiple crumbs at a time.  If the crumb is empty the 
   * event `tkAddReportToCrumb` is triggered so the calling code can simply add the
   * new selections to the crumb list.
   * However, if the crumbs are not empty, `tkCrumbAddDialog` is triggered so a 
   * Dialog that asks "Append" or "Replace" is given to the user.
   *
   * @example
   * tk.crumbs.askAddCrumb("ENTITY");
   * 
   * @author Angel Flores
   * @created Tuesday, June 28, 2022
   * @param pEntityType Crumbs Entity Type
   */
  askAddCrumb: async function(pEntityType) {

    var crumInfo = await tk.crumbs.crumbInfo(pEntityType);
    if (crumInfo.crumbEmpty) {
      apex.event.trigger(document, 'tkAddReportToCrumb');
    } else {
      apex.event.trigger(document, 'tkCrumbAddDialog');
    }
  }


};

})(tk, apex.jQuery);
