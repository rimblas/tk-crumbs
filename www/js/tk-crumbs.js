var tk = tk || {};


(function(tk, $, undefined) {

tk.crumbs = {

  init: function() {
    apex.jQuery( "div.crumbs .removeCrumb" ).on( "click", function(e) {
      tk.crumbs.removeCrumb(this.dataset.crumbid);
      e.preventDefault();
    });
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
              }
          }
      );
  }
};

})(tk, apex.jQuery);
