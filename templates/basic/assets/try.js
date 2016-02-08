$(document).ready(function() {
  //
  // Form submission
  //
  $('form').on('submit', function() {

    // Gets values used to make up the URL which should be
    // requested for this request.
    var host = $("input[name=host]", $(this)).val()
    var version = $("input[name=version]", $(this)).val()
    var controller = $("input[name=controller]", $(this)).val()
    var action = $("input[name=action]", $(this)).val()
    var url = host + "/api/" + version + "/" + controller + "/" + action
    // Get all fields which will be added as headers
    var headerFields = $('input.headerField', $(this))
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
        } else {
          parameters[name] = value;
        }
      }
    });
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
          value = $field.val()
          if(value.length) {
            xhr.setRequestHeader($field.attr('name'), $field.val())
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
      error: function() {
        // Errors which occurr aren't very well reported at the moment.
        // They should be.
        outputBox.show()
        outputBox.text("Failed to make request.")
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
});
