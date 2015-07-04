# gibbon

Gibbon is an API wrapper for MailChimp's [Primary and Export APIs](http://www.mailchimp.com/api).

[![Build Status](https://secure.travis-ci.org/amro/gibbon.png)](http://travis-ci.org/amro/gibbon)
[![Dependency Status](https://gemnasium.com/amro/gibbon.png)](https://gemnasium.com/amro/gibbon)
##Important Notes

Gibbon now targets MailChimp API 2.0, which is substantially different from API 1.3. Please use Gibbon 0.4.6 if you need to use API 1.3.

* Supports MailChimp API 2.0 and Export API 1.0
* Errors are raised by default
* Timeouts can be specified per request during initialization

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

    info = gb.lists.member_info({:id => list_id, :emails => [{:email => email_1}, {:email => email_2}]})

List subscribers for a list:

    gb.lists.members({:id => list_id})

or

List unsubscribed members for a list

    gb.lists.members({:id => list_id, :status => "unsubscribed"})

Subscribe a member to a list:

    gb.lists.subscribe({:id => list_id, :email => {:email => 'email_address'}, :merge_vars => {:FNAME => 'First Name', :LNAME => 'Last Name'}, :double_optin => false})

Here's an example showing pagination. The following code fetches the first page of 100 members subscribed to your list:

    gb.lists.members({:id => list_id, :opts => {:start => 0, :limit => 100}})

or

Batch subscribe members to a list:

    gb.lists.batch_subscribe(:id => list_id, :batch => [{:email => {:email => "email1"}, :merge_vars => {:FNAME => "FirstName1", :LNAME => "LastName1"}},{:email => {:email =>"email2"}, :merge_vars => {:FNAME => "FirstName2", :LNAME => "LastName2"}}])

> Note: This will send welcome emails to the new subscribers

If you want to update the existing members you need to send the boolean update_existing in true

    gb.lists.batch_subscribe(:id => list_id, :batch => [{:email => {:email => "email1"}, :merge_vars => {:FNAME => "FirstName1", :LNAME => "LastName1"}}], :update_existing => true)

> Note: The `email` hash can also accept either a unique email id or a list email id. Please see the [lists/batch-subscribe](http://apidocs.mailchimp.com/api/2.0/lists/batch-subscribe.php) documentation for more information.

You can also unsubscribe a member from a list:

    gb.lists.unsubscribe(:id => list_id, :email => {:email => "user_email"}, :delete_member => true, :send_notify => true)

> Note: :delete_member defaults to false, meaning the member stays on your mailchimp list as "unsubscribed".  See [Api Docs](http://apidocs.mailchimp.com/api/2.0/lists/unsubscribe.php) for details of options.

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
at the bottom of each page. Here's how you might do that:

    begin
      g.lists.subscribe(...)
    rescue Gibbon::MailChimpError => e
      # do something with e.message here
      # do something wiht e.code here
    end

Some API endpoints, like `[lists/batch-subscribe](http://apidocs.mailchimp.com/api/2.0/lists/batch-subscribe.php)`
return errors to let you know that some of your actions failed, but some suceeded. Gibbon will not
raise Gibbon::MailChimpError for these endpoints because the key for the success count varies from endpoint to endpoint.
This makes it difficult to determine whether all of your actions failed in a generic way. **Because of this, you're responsible
for checking the response body for the `errors` array in these cases.**

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

    gibbon_export.list({:id => *list_id*})

One can also use this in a streaming fashion, where each row is parsed on it comes in like this:

    gibbon_export.list({:id => *list_id*}) { |row| *do_sth_with* row }

For the streaming functionality, it is important to supply an explicit block / procedure to the export functions, not an implicit one. So, the preceding and following one will work. Please note this method also includes a counter (*i*, starting at 0) telling which row of data you're receiving:
```
    method = Proc.new do |row, i|
        *do_sth_with* row
    end
    gibbon_export.list(params, &method)
```

Please note, the following example gives a block that is outside of the function and therefore **won't** work:
```
    gibbon_export.list({:id => *list_id*}) do |row|
        *do_sth_with* row
    end
```

##Thanks

Thanks to everyone who's [contributed](https://github.com/amro/gibbon/contributors) to Gibbon's development. Major props to The Viking for making MailChimp API 2.0 great.

##Copyright

* Copyright (c) 2010-2015 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2015 The Rocket Science Group.
