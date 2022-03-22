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
  }
};

})(tk, apex.jQuery);
