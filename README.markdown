# gibbon

Gibbon is an API wrapper for MailChimp's [API](http://kb.mailchimp.com/api/).

[![Build Status](https://secure.travis-ci.org/amro/gibbon.png)](http://travis-ci.org/amro/gibbon)
[![Dependency Status](https://gemnasium.com/amro/gibbon.png)](https://gemnasium.com/amro/gibbon)
##Important Notes

Gibbon now targets MailChimp API 3.0, which is substantially different from the previous API. Please use Gibbon 1.1.x if you need to use API 2.0.

Please read MailChimp's [Getting Started Guide](http://kb.mailchimp.com/api/article/api-3-overview).

##Installation

    $ gem install gibbon

##Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

##Usage

First, create an instance Gibbon::Request:

    gibbon = Gibbon::Request.new(api_key: "your_api_key")

You can set an individual request's timeout like this:

    gibbon.timeout = 10

Now you can make requests using the resources defined in [MailChimp's docs](http://kb.mailchimp.com/api/resources). Resource IDs
are specified inline and a `CRUD` (`create`, `retrieve`, `update`, or `delete`) verb initiates the request.

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

MailChimp's [resource documentation](http://kb.mailchimp.com/api/resources) is a list of available resources. Substitute an underscore if
a resource name contains a hyphen.

### Fetching Campaigns


    campaigns = gb.campaigns.retrieve

### Fetching Lists

Similarly, to fetch your lists

    lists = gb.lists.retrieve

### More Advanced Examples

List subscribers for a list:

    gb.lists(list_id).members.retrieve

Subscribe a member to a list:

    gb.lists(list_id).members.create(body: {email_address: "email_address", status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})

You can also unsubscribe a member from a list:

    gb.lists(list_id).members(member_id).update(body: { status: "unsubscribed" })

Fetch the number of opens for a campaign

    email_stats = gb.reports("13e9a94053").retrieve["opens"]

Overriding Gibbon's API endpoint (i.e. if using an access token from OAuth and have the `api_endpoint` from the [metadata](http://apidocs.mailchimp.com/oauth2/)):

    Gibbon::Request.api_endpoint = "https://us1.api.mailchimp.com"
    Gibbon::Request.api_key = your_access_token_or_api_key

### Error handling

Gibbon raises an error when the API returns an error.

Gibbon::MailChimpError has the following attributes: `title`, `detail`, `body`, `raw_body`, `status_code`. Some or all of these may not be
available depending on the nature of the error.

##Thanks

Thanks to everyone who has [contributed](https://github.com/amro/gibbon/contributors) to Gibbon's development.

##Copyright

* Copyright (c) 2010-2015 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2015 The Rocket Science Group.
