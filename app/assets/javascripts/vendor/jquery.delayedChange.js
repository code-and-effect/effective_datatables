// http://stackoverflow.com/questions/7373023/throttle-event-calls-in-jquery

(function($) {
  $.fn.delayedChange = function(options) {
    var timer; var o;

    if (jQuery.isFunction(options)) {
      o = { onChange: options };
    } else {
      o = options;
    }

    o = $.extend({}, $.fn.delayedChange.defaultOptions, o);

    return this.each(function() {
      var element = $(this);
      element.keyup(function() {
        clearTimeout(timer);
        timer = setTimeout(function() {
          var newVal = element.val();
          if (element.delayedChange.oldVal != newVal) {
            element.delayedChange.oldVal = newVal;
            o.onChange.call(this, element);
          }
        }, o.delay);
      });
    });
  };

  $.fn.delayedChange.defaultOptions = {
    delay: 700,
    onChange: function(element) { }
  }

  $.fn.delayedChange.oldVal = 'NO_DELAYED_CHANGE_VALUE';

})(jQuery);
