require 'test_helper'

class FapiClientTest < ActiveSupport::TestCase

  setup do
    @client ||= FapiClient.new
  end

  should 'trigger fapi on translation change' do
    orga = create(:orga)

    result = mock()
    result.stubs(:body).returns({status: 'ok'}.to_json)
    Net::HTTP.any_instance.expects(:request).with do |req|
      query = CGI::parse(URI::parse(req.path).query) # wtf, there is no method to parse an url query into a hash???
      assert_equal 'orga', query['type'][0]
      assert_equal orga.id.to_s, query['id'][0]
      assert_equal 'fr', query['locale'][0]
      assert_equal Settings.afeefa.fapi_webhook_api_token, query['token'][0]
    end
    .returns(result)

    status = @client.entry_translated(orga, 'fr')

    assert_equal 'ok', JSON.parse(status)['status']
  end

  should 'trigger fapi on entry update' do
    orga = create(:orga)

    result = mock()
    result.stubs(:body).returns({status: 'ok'}.to_json)
    Net::HTTP.any_instance.expects(:request).with do |req|
      query = CGI::parse(URI::parse(req.path).query) # wtf, there is no method to parse an url query into a hash???
      assert_equal 'orga', query['type'][0]
      assert_equal orga.id.to_s, query['id'][0]
      assert_nil query['locale'][0]
      assert_equal Settings.afeefa.fapi_webhook_api_token, query['token'][0]
    end
    .returns(result)

    status = @client.entry_updated(orga)

    assert_equal 'ok', JSON.parse(status)['status']
  end

  should 'trigger fapi on update all' do
    orga = create(:orga)

    result = mock()
    result.stubs(:body).returns({status: 'ok'}.to_json)
    Net::HTTP.any_instance.expects(:request).with do |req|
      query = CGI::parse(URI::parse(req.path).query) # wtf, there is no method to parse an url query into a hash???
      assert_nil query['type'][0]
      assert_nil query['id'][0]
      assert_nil query['locale'][0]
      assert_equal Settings.afeefa.fapi_webhook_api_token, query['token'][0]
    end
    .returns(result)

    status = @client.all_updated

    assert_equal 'ok', JSON.parse(status)['status']
  end

  should 'trigger fapi on delete entry' do
    orga = create(:orga)

    result = mock()
    result.stubs(:body).returns({status: 'ok'}.to_json)
    Net::HTTP.any_instance.expects(:request).with do |req|
      query = CGI::parse(URI::parse(req.path).query) # wtf, there is no method to parse an url query into a hash???
      assert_equal 'dresden', query['area'][0]
      assert_equal 'orga', query['type'][0]
      assert_equal orga.id.to_s, query['id'][0]
      assert_nil query['locale'][0]
      assert query['deleted'][0]
      assert_equal Settings.afeefa.fapi_webhook_api_token, query['token'][0]
    end
    .returns(result)

    status = @client.entry_deleted(orga)

    assert_equal 'ok', JSON.parse(status)['status']
  end

end
