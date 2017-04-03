$(document).ready(function() {

  $form = $('form.tryForm')

  // Get all fields which will be added as headers
  var headerFields = $('input.headerField', $form)

  // Add stored values to header fields
  if(typeof(Storage) !== "undefined") {
    headerFields.each(function() {
      $field = $(this)
      $field.val(localStorage.getItem("header__" + $(this).attr('name')))
    })

  }


  //
  // Form submission
  //
  $form.on('submit', function() {

    // Gets values used to make up the URL which should be
    // requested for this request.
    var host = $("input[name=host]", $(this)).val()
    var version = $("input[name=version]", $(this)).val()
    var controller = $("input[name=controller]", $(this)).val()
    var action = $("input[name=action]", $(this)).val()
    var url = host + "/api/" + version + "/" + controller + "/" + action
    // Get the output box ready for use
    var outputBox = $('.tryForm__output', $(this))
    // Create a hash fo all parameters which will be submitted
    var parameters = {}
    $('input.paramField').each(function(){
      $this = $(this)
      value = $this.val()
      type = $this.data('type')
      name = $this.attr('name')
      if(value.length) {
        if(type == 'Integer') {
          parameters[name] = parseInt(value);
        } else if (type == "Hash" || type == "Array") {
          parameters[name] = JSON.parse(value);
        } else {
          parameters[name] = value;
        }
      }
    });

    // Include/exclude full attributes as needed
    var fullAttrsCheckbox = $('#full_attrs')
    if(fullAttrsCheckbox.length) {
      parameters['_full'] = !!fullAttrsCheckbox.prop('checked')
    }

    // Include/exclude expansions
    var expansionCheckboxes = $('.tryForm__expansions')
    if(expansionCheckboxes.length) {
      parameters['_expansions'] = []
      expansionCheckboxes.each(function() {
        $this = $(this)
        name = $(this).attr('name')
        if($(this).prop('checked')) {
          parameters['_expansions'].push(name)
        }
      })
    }

    // Make the AJAX request
    $.ajax({
      url: url,
      method: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(parameters),
      beforeSend: function(xhr) {
        // Add any headers which have been added
        headerFields.each(function() {
          $field = $(this)
          name = $field.attr('name')
          value = $field.val()
          if(typeof(Storage) !== "undefined") {
            localStorage.setItem("header__" + name, value)
          }
          if(value.length) {
            xhr.setRequestHeader(name, $field.val())
          }
        })
      },
      success: function(data) {
        // Success means that we got a 200 OK which means we can be pretty
        // sure that we've got a moonrope response.
        if(data.status == "success") {
          outputBox.addClass('tryForm__output--success').removeClass('tryForm__output--error')
        } else {
          outputBox.addClass('tryForm__output--error').removeClass('tryForm__output--success')
        }
        outputBox.text(JSON.stringify(data, null, 4))
        outputBox.show()
      },
      error: function(xhr) {
        // Errors which occurr aren't very well reported at the moment.
        // They should be.
        if(xhr.getResponseHeader('content-type') == 'application/json') {
          var text = JSON.stringify(JSON.parse(xhr.responseText), null, 4)
        } else {
          var text = "Failed to make request."
        }

        outputBox.show()
        outputBox.text(text)
        outputBox.addClass('tryForm__output--error').removeClass('tryForm__output--success')
      }
    })
    return false
  });

  //
  // Open the try form
  //
  $('p.tryFormActivate a').on('click', function() {
    $form = $('form.tryForm')
    $parent = $(this).parents('p')
    $form.show('fast')
    $parent.hide()
    return false
  });

  //
  // Close the try form
  //
  $('button.tryFormCancel').on('click', function() {
    $form = $('form.tryForm')
    $parent = $('p.tryFormActivate')
    $form.hide()
    $parent.show()
    return false
  });

  // http://stackoverflow.com/questions/8100770/auto-scaling-inputtype-text-to-width-of-value
  // http://jsfiddle.net/MqM76/217/
  $.fn.textWidth = function(text, font) {
      if (!$.fn.textWidth.fakeEl) $.fn.textWidth.fakeEl =      $('<span>').hide().appendTo(document.body);
      $.fn.textWidth.fakeEl.text(text || this.val() || this.text()).css('font', font || this.css('font'));
      return $.fn.textWidth.fakeEl.width();
  };

  // Automatically ensure that the size for the header inputs is
  // correct
  function resizeInput() {
    $this = $(this)
    $this.css('width', $this.textWidth() + "px")
    $this.attr('size', $this.val().length)
  }

  $('form.tryForm .tryForm__header input').on('input', resizeInput).trigger('input')

});
