I think FB's layout is toooooooo ugly.

This tool is to show your facebook today's (or specified day's) messages.
Make sure you've added application.yml to config dir if you use this package.

application.yml:

defaults: &defaults
  fb_app: 'APP_ID'
  fb_secret: 'APP_SECRET'
  fb_domain: 'http://www.facebook.com'
  fb_graph: 'http://graph.facebook.com'
  profile_picture_arg: 'picture?type=square&width=100&height=100'

development:
  <<: *defaults
  site_url: 'http://localhost:3000/'
production:
  <<: *defaults
  site_url : 'PRODUCTION_SITE'
