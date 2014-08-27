// something
$(document).ready(function() {
  $('#player-selector tr')
    .filter(':has(:checkbox:checked)')
    .addClass('info')
    .end()
  .click(function(event) {
    $(this).toggleClass('info');
    if (event.target.type !== 'checkbox') {
      $(':checkbox', this).prop('checked', function() {
        return !this.checked;
      });
    }
  });
});
