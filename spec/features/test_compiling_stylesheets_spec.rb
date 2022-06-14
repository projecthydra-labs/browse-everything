# frozen_string_literal: true

describe 'Compiling the stylesheets', type: :feature, js: true do
  it 'does not raise errors' do
    visit '/'
    expect(page).not_to have_content 'Sass::SyntaxError'
  end
end
