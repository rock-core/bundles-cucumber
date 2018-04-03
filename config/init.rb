Roby.app.using 'syskit'

Roby.app.search_path << File.expand_path("../../common_models", __dir__)

require 'roby/schedulers/temporal'
Roby.scheduler = Roby::Schedulers::Temporal.new

