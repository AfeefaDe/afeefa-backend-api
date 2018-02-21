require 'test_helper'

class Api::V1::ChaptersControllerTest < ActionController::TestCase

  context 'as authorized user' do
    setup do
      stub_current_user
    end

    should 'get show without login' do
      WebMock.stub_request(:get, "#{@controller.base_path}/1").to_return(body: chapter.to_json)
      unstub_current_user

      get :show, params: { id: 1 }
      assert_response :ok, response.body
      assert_equal chapter.to_json, response.body

      WebMock.assert_requested(:get, "#{@controller.base_path}/1")
    end

    should 'get empty list of chapters' do
      WebMock.stub_request(:get, "#{@controller.base_path}").to_return(body: '[]')

      get :index
      assert_response :ok, response.body
      json = JSON.parse(response.body)
      assert_equal [], json
    end

    should 'create chapter' do
      chapter = {
        id: 1,
        title: 'dummy chapter',
        content: '<html></html>',
        order: 1
      }
      WebMock.stub_request(:post, "#{@controller.base_path}").to_return(status: 201, body: chapter.to_json)

      post :create, params: chapter.except(:id)
      assert_response :created, response.body
      assert_equal chapter.to_json, response.body

      WebMock.assert_requested(:post, "#{@controller.base_path}")
    end
  end

end
