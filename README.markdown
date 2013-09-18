# gibbon

Gibbon is an API wrapper for MailChimp's [Primary and Export APIs](http://www.mailchimp.com/api).

[![Build Status](https://secure.travis-ci.org/amro/gibbon.png)](http://travis-ci.org/amro/gibbon)

##Important Notes About Version 0.5.0+
### (It's different!)

Gibbon now targets MailChimp API 2.0, which is substantially different from API 1.3. Please use Gibbon 0.4.6 if you need to use API 1.3.

* Supports MailChimp API 2.0 and Export API 1.0
* Errors are raised by default since 0.4.x
* Timeouts can be specified per request during initialization
* Ruby 1.9.x+ for now. A future version may be Ruby 2.0 only to take advantage of lazy iteration when using the Export API.

##Installation

    $ gem install gibbon

##Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

##Usage

There are a few ways to use Gibbon:

You can create an instance of the API wrapper:

    gb = Gibbon::API.new("your_api_key")

You can set `api_key`, `timeout` and `throws_exceptions` globally:

    Gibbon::API.api_key = "your_api_key"
    Gibbon::API.timeout = 15
    Gibbon::API.throws_exceptions = false
		
similarly

    Gibbon::Export.api_key = "your_api_key"
    Gibbon::Export.timeout = 15
    Gibbon::Export.throws_exceptions = false
    
For example, you could set the values above in an `initializer` file in your `Rails` app (e.g. your\_app/config/initializers/gibbon.rb).

Assuming you've set an `api_key` on Gibbon, you can conveniently make API calls on the class itself:

    Gibbon::API.lists.list

You can also set the environment variable `MAILCHIMP_API_KEY` and Gibbon will use it when you create an instance:

    gb = Gibbon::API.new

> Note: In an effort to simplify Gibbon, the environment variable 'MC_API_KEY' is no longer available as of version 0.4.0. Please use 'MAILCHIMP_API_KEY' instead.

Fetching data is as simple as calling API methods directly on the wrapper
object with a given category (e.g. campaigns.list).  The API calls may be made with either camelcase or  underscore
separated formatting as you see in the "More Advanced Examples" section below.

Check the API [documentation](http://apidocs.mailchimp.com/api/2.0/) for details.

### Fetching Campaigns

For example, to fetch your first 100 campaigns (page 0):

    campaigns = gb.campaigns.list({:start => 0, :limit => 100})

### Fetching Lists

Similarly, to fetch your first 100 lists:

    lists = gb.lists.list({:start => 0, :limit=> 100})

Or, to fetch a list by name:

    list = gb.lists.list({:filters => {:list_name => list_name}})

### More Advanced Examples

Getting batch member information for subscribers looks like this:

    info = gb.lists.member_info({:id => list_id, :emails => email_array})

List subscribers for a list:

    gb.lists.members({:id => list_id})

or

List unsubscribed members for a list

    gb.lists.members({:id => list_id, :status => "unsubscribed"})

Subscribe a member to a list:

    gb.lists.subscribe({:id => list_id, :email => {:email => 'email_address'}, :merge_vars => {:FNAME => 'First Name', :LNAME => 'Last Name'}, :double_optin => false})

> Note: This will send a welcome email to the new subscriber

or

Batch subscribe members to a list:

    gb.lists.batch_subscribe(:id => list_id, :batch => [{:EMAIL => {:email => "email1"}, :FNAME => "FirstName1", :LNAME => "LastName1"},{:EMAIL => {:email =>"email2"}, :FNAME => "FirstName2", :LNAME => "LastName2"}])

> Note: This will send welcome emails to the new subscribers

If you want to update the existing members you need to send the boolean update_existing in true

    gb.lists.batch_subscribe(:id => list_id, :batch => [{:EMAIL => {:email => "email1"}, :FNAME => "FirstName1", :LNAME => "LastName1"}], :update_existing => true)
    
> On :EMAIL you can send the :euid (the unique id for an email address) or the :leid (the list email id) too, instead :email.

Fetch recipients who opened particular campaign:

    email_stats = gb.reports.opened({:cid => campaign_id})

or

Create a campaign:

    gb.campaigns.create({type: "regular", options: {list_id: list_id, subject: "Gibbon is cool", from_email: "you@example.com", from_name: "Darth Vader", generate_text: true}, content: {html: "<html><head></head><body><h1>Foo</h1><p>Bar</p></body></html>"}})

Overriding Gibbon's API endpoint (i.e. if using an access token from OAuth and have the `api_endpoint` from the [metadata](http://apidocs.mailchimp.com/oauth2/)):

    Gibbon::API.api_endpoint = "https://us1.api.mailchimp.com"
    Gibbon::API.api_key = your_access_token_or_api_key

### Setting timeouts

Gibbon defaults to a 30 second timeout. You can optionally set your own timeout (in seconds) like so:

    gb = Gibbon::API.new("your_api_key", {:timeout => 5})

or

    gb.timeout = 5

### Error handling

By default Gibbon will attempt to raise errors returned by the API automatically.

If you set the `throws_exceptions` boolean attribute to false, for a given instance,
then Gibbon will not raise exceptions. This allows you to handle errors manually. The
APIs will return a Hash with two keys "errors", a string containing some textual
information about the error, and "code", the numeric code of the error.

If you rescue Gibbon::MailChimpError, you are provided with the error message itself as well as
a `code` attribute that you can map onto the API's error list. The API docs list possible errors
at the bottom of each page.

> Note: In an effort to make Gibbon easier to use, errors are raised automatically as of version 0.4.0.

### Export API usage

In addition to the primary API, you can make calls to the [Export API](http://apidocs.mailchimp.com/export/1.0/) using an instance of GibbonExport.  Given an existing instance of Gibbon, you can request a new GibbonExporter object:

    g = Gibbon::API.new("your_api_key")
    gibbon_export = g.get_exporter

or you can construct a new object directly:

    gibbon_export = Gibbon::Export.new("your_api_key")

Making calls to Export API endpoints is similar to making standard API calls but the
return value is an Enumerator which loops over the lines returned from the
Export API. This is because the data returned from the Export API is a stream
of JSON objects rather than a single JSON array.

For example, dumping list members via the "list" method works like this:

    gibbon_export.list({id => list_id})

##Thanks

Thanks to everyone who's [contributed](https://github.com/amro/gibbon/contributors) to Gibbon's development. Major props to Jesse at MailChimp for adding nice stuff in API 2.0 that makes it easier to develop against.

##Copyright

* Copyright (c) 2010-2013 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2013 The Rocket Science Group.
