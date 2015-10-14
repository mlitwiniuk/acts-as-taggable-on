# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActsAsTaggableOn::Tagging do
  before(:each) do
    @tagging = ActsAsTaggableOn::Tagging.new
  end

  it 'should not be valid with a invalid tag' do
    @tagging.taggable = TaggableModel.create(name: 'Bob Jones')
    @tagging.tag = ActsAsTaggableOn::Tag.new(name: '')
    @tagging.context = 'tags'

    expect(@tagging).to_not be_valid

    expect(@tagging.errors[:tag_id]).to eq(['can\'t be blank'])
  end

  it 'should not create duplicate taggings' do
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @tag = ActsAsTaggableOn::Tag.create(name: 'awesome')

    expect(-> {
      2.times { ActsAsTaggableOn::Tagging.create(taggable: @taggable, tag: @tag, context: 'tags') }
    }).to change(ActsAsTaggableOn::Tagging, :count).by(1)
  end

  it 'should not delete tags of other records' do
    6.times { TaggableModel.create(name: 'Bob Jones', tag_list: 'very, serious, bug') }
    expect(ActsAsTaggableOn::Tag.count).to eq(3)
    taggable = TaggableModel.first
    taggable.tag_list = 'bug'
    taggable.save

    expect(taggable.tag_list).to eq(['bug'])

    another_taggable = TaggableModel.where('id != ?', taggable.id).sample
    expect(another_taggable.tag_list.sort).to eq(%w(very serious bug).sort)
  end

  it 'should destroy unused tags after tagging destroyed' do
    previous_setting = ActsAsTaggableOn.remove_unused_tags
    ActsAsTaggableOn.remove_unused_tags = true
    ActsAsTaggableOn::Tag.destroy_all
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @taggable.update_attribute :tag_list, 'aaa,bbb,ccc'
    @taggable.update_attribute :tag_list, ''
    expect(ActsAsTaggableOn::Tag.count).to eql(0)
    ActsAsTaggableOn.remove_unused_tags = previous_setting
  end

  it 'should destroy unused tags for given contexts after tagging destroyed' do
    previous_setting = ActsAsTaggableOn.remove_unused_tags
    previous_setting_context = ActsAsTaggableOn.remove_unused_tags_by_context.dup
    ActsAsTaggableOn.remove_unused_tags = true
    ActsAsTaggableOn.remove_unused_tags_by_context = %w( tags )
    ActsAsTaggableOn::Tag.destroy_all
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @taggable.update_attribute :tag_list, 'aaa,bbb,ccc'
    @taggable.update_attribute :tag_list, ''
    expect(ActsAsTaggableOn::Tag.count).to eql(0)
    ActsAsTaggableOn.remove_unused_tags = previous_setting
    ActsAsTaggableOn.remove_unused_tags_by_context = previous_setting_context
  end

  it 'should no destroy unused tags if context does not match after tagging destroyed' do
    previous_setting = ActsAsTaggableOn.remove_unused_tags
    previous_setting_context = ActsAsTaggableOn.remove_unused_tags_by_context.dup
    ActsAsTaggableOn.remove_unused_tags = true
    ActsAsTaggableOn.remove_unused_tags_by_context = %w( something_stupid )
    ActsAsTaggableOn::Tag.destroy_all
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @taggable.update_attribute :tag_list, 'aaa,bbb,ccc'
    @taggable.update_attribute :tag_list, ''
    expect(ActsAsTaggableOn::Tag.count).to eql(3)
    ActsAsTaggableOn.remove_unused_tags = previous_setting
    ActsAsTaggableOn.remove_unused_tags_by_context = previous_setting_context
  end

  pending 'context scopes' do
    describe '.by_context'

    describe '.by_contexts'

    describe '.owned_by'

    describe '.not_owned'

  end

end
