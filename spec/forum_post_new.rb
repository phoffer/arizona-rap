require 'rest_client'
require 'nokogiri'
require 'net/http'
require 'uri'

login_url = 'http://forum.prodigaleyelid.com/ucp.php?mode=login'
login_data = {  'username' => 'prh',
                'password' => 'goazcats',
                'autologin' => true,
                'viewonline' => true,
                'redirect' => 'index.php',
                'login' => 'Login'
              }

post_options = {
                  "disable_bbcode" => false,
                  "disable_smilies" => false,
                  'disable_magic_url' => false,
                  'attach_sig' => true,
                  'notify' => false,
                  # 'fileupload' => nil,
                  'filecomment' => '',
                  'poll_title' => '',
                  'poll_option_text' => '',
                  'poll_max_options' => 1,
                  'poll_length' => 0,
                  'poll_vote_change' => false,
                  'phpbbtotwitter-text' => false
}

post_url  = 'http://forum.prodigaleyelid.com/posting.php?mode=post&f=14'
form_data = {
              'subject' => 'Test subject line',
              'message' => "Just trying something new.\n\n\n",
              # 'lastclick' => '1408832590',
              'name' => 'Login',
              'preview' => 'Preview',
              'post' => 'Submit'
              # 'form_token' => 'a5ca42ae61a9019d3de049b5e0985d3b48aefef6',
              # 'creation_time' => '1408832590'
            }

# Net::HTTP.post_form URI(url),
#                     { "q" => "ruby", "max" => "50" }
# 1408832460

response = RestClient.post(login_url, login_data)
response.cookies
# puts response.cookies
# puts response.body
doc = Nokogiri::HTML(RestClient.get('http://forum.prodigaleyelid.com/posting.php?mode=post&f=14', {cookies: response.cookies}).body)
form_token = doc.xpath('//*[@id="options-panel"]/div/input[2]')
creation_time = doc.xpath('//*[@id="options-panel"]/div/input[1]')
lastclick = doc.xpath('//*[@id="postform"]/div[2]/div/fieldset/input[1]')
form_data['form_token']    = form_token.attr('value').to_s
form_data['creation_time'] = creation_time.attr('value').to_s
form_data['lastclick']     = lastclick.attr('value').to_s
# form_data['form_token'] = form_token.attr('value').to_s
puts form_data.inspect
# exit
sleep 3
response2 = RestClient.post(
  post_url,
  form_data,
  {:cookies => response.cookies}
)
# puts response2.body
