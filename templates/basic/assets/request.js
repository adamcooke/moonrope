$(document).ready(function() {
  $('form').on('submit', function() {
    var host = $("input[name=host]", $(this)).val()
    var version = $("input[name=version]", $(this)).val()
    var controller = $("input[name=controller]", $(this)).val()
    var action = $("input[name=action]", $(this)).val()
    var headerFields = $('input.headerField')
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
    var outputBox = $('#outputBox')
    var url = host + "/api/" + version + "/" + controller + "/" + action
    $.ajax({
      url: url,
      method: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(data),
      beforeSend: function(xhr) {
        headerFields.each(function() {
          $field = $(this)
          xhr.setRequestHeader($field.attr('name'), $field.val())
        })
      },
      success: function(data) {
        outputBox.text(JSON.stringify(data, null, 4))
      },
      error: function() {
        outputBox.text("Failed to make request.")
      }
    })
    return false
  })
})
