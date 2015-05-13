# gibbon

Gibbon is an API wrapper for MailChimp's [API](http://kb.mailchimp.com/api/).

[![Build Status](https://secure.travis-ci.org/amro/gibbon.png)](http://travis-ci.org/amro/gibbon)
[![Dependency Status](https://gemnasium.com/amro/gibbon.png)](https://gemnasium.com/amro/gibbon)
##Important Notes

Gibbon now targets MailChimp API 3.0, which is substantially different from the previous API. Please use Gibbon 1.1.5 if you need to use API 2.0.

##Installation

    $ gem install gibbon

##Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

##Usage

First, create an instance Gibbon::Request:

    gibbon = Gibbon::Request.new(api_key: "your_api_key")

Your API key should be of the form XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-DCX.

You can set an individual request's timeout like this:

    gibbon.timeout = 10

Now you can make requests using the resources defined in [MailChimp's docs](http://kb.mailchimp.com/api/resources). Resource IDs
are specified inline and a `CRUD` (`create`, `retrieve`, `, `update`, or `delete`) verb initiates the request.

    gibbon.lists.retrieve
 
Retrieving a specific list looks like:

    gibbon.lists(list_id).retrieve

Retrieving a specific list's members looks like:

    gibbon.lists(list_id).members.retrieve

You can also specify `headers`, `params`, and `body` when calling a `CRUD` method. For example:

    gibbon.lists.retrieve(headers: {"SomeHeader": "SomeHeaderValue"}, params: {"query_param": "query_param_value"})

Of course, `body` is only supported on `create` and `update` calls. Those map to HTTP `POST` and `PATCH` verbs.

You can set `api_key` and `timeout` globally:

    Gibbon::Request.api_key = "your_api_key"
    Gibbon::Request.timeout = 15

For example, you could set the values above in an `initializer` file in your `Rails` app (e.g. your\_app/config/initializers/gibbon.rb).

Assuming you've set an `api_key` on Gibbon, you can conveniently make API calls on the class itself:

    Gibbon::Request.lists.retrieve

You can also set the environment variable `MAILCHIMP_API_KEY` and Gibbon will use it when you create an instance:

    gb = Gibbon::Request.new

MailChimp's [resource documentation](http://kb.mailchimp.com/api/resources) is a list of availabel resources. Substitue an underscore if
a resource name contains a hyphen.

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

### Error handling

Gibbon raises an error when the API returns an error.

Gibbon::MailChimpError has the following attributes: `title`, `detail`, `body`, `raw_body`, `status_code`. Some or all of these may not be
available depending on the nature of the error.

##Thanks

Thanks to everyone who's [contributed](https://github.com/amro/gibbon/contributors) to Gibbon's development.

##Copyright

* Copyright (c) 2010-2015 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2015 The Rocket Science Group.
