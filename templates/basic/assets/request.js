$(document).ready(function() {
  $('form').on('submit', function() {
    var host = $("input[name=host]", $(this)).val()
    var version = $("input[name=version]", $(this)).val()
    var controller = $("input[name=controller]", $(this)).val()
    var action = $("input[name=action]", $(this)).val()
    var headerFields = $('input.headerField', $(this))
    var data = {}
    $('input.paramField').each(function(){
      $this = $(this)
      value = $this.val()
      type = $this.data('type')
      name = $this.attr('name')
      if(value.length) {
        if(type == 'Integer') {
          data[name] = parseInt(value);
        } else {
          data[name] = value;
        }
      }
    });
    var outputBox = $('.tryForm__output', $(this))
    var url = host + "/api/" + version + "/" + controller + "/" + action
    $.ajax({
      url: url,
      method: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(data),
      beforeSend: function(xhr) {
        headerFields.each(function() {
          $field = $(this)
          value = $field.val()
          if(value.length) {
            xhr.setRequestHeader($field.attr('name'), $field.val())
          }
        })
      },
      success: function(data) {

        if(data.status == "success") {
          outputBox.addClass('tryForm__output--success').removeClass('tryForm__output--error')
        } else {
          outputBox.addClass('tryForm__output--error').removeClass('tryForm__output--success')
        }
        outputBox.text(JSON.stringify(data, null, 4))
        outputBox.show()
      },
      error: function() {
        outputBox.show()
        outputBox.text("Failed to make request.")
        outputBox.addClass('tryForm__output--error').removeClass('tryForm__output--success')
      }
    })
    return false
  });

  $('p.tryFormActivate a').on('click', function() {
    $form = $('form.tryForm')
    $parent = $(this).parents('p')
    $form.show('fast')
    $parent.hide()
    return false
  });

  $('button.tryFormCancel').on('click', function() {
    $form = $('form.tryForm')
    $parent = $('p.tryFormActivate')
    $form.hide()
    $parent.show()
    return false
  });
})
