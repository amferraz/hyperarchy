(function(Monarch) {

//= require <jquery-1.5.2>
//= require <jquery.ba-bbq>
//= require <htmlescape>
//= require <underscore>
//= require <json>
//= require <md5>
//= require "monarch/language_extensions"
//= require "monarch/underscore_extensions"
//= require "monarch/foundation"
//= require "monarch/define_monarch"
//= require "monarch/jquery.monarch"
//= require "monarch/subscription_node"
//= require "monarch/subscription"
//= require "monarch/subscription_bundle"
//= require "monarch/future"
//= require "monarch/queue"
//= require "monarch/skip_list"
//= require "monarch/inflection"
//= require "monarch/view"
//= require "monarch/http"
//= require "monarch/model"
//= require "monarch/promise"

Server = new Monarch.Http.Server();
Repository = new Monarch.Model.Repository();
History = new Monarch.View.History();

})(Monarch);
