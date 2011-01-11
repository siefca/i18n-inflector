require 'test_helper'

class I18nBackendInflectionTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::Inflector
    include I18n::Backend::Fallbacks
  end

  def setup
    I18n.backend = Backend.new
    store_translations(:xx, :i18n => { :inflections => {
                                            :gender => {
                                              :m => 'male',
                                              :f => 'female',
                                              :n => 'neuter',
                                              :s => 'strange',
                                              :masculine  => '@m',
                                              :feminine   => '@f',
                                              :neuter     => '@n',
                                              :neutral    => '@neuter',
                                              :default    => 'neutral' },
                                            :person => {
                                              :i   => 'I',
                                              :you => 'You'}
                                        }   })

    store_translations(:xx, 'welcome' => 'Dear @{f:Lady|m:Sir|n:You|All}!')
  end

  test "inflector has methods to test its switches" do
    assert_equal true,  I18n.backend.inflector_unknown_defaults   = true
    assert_equal false, I18n.backend.inflector_excluded_defaults  = false
    assert_equal false, I18n.backend.inflector_raises             = false
    assert_equal false, I18n.backend.inflector_raises?
    assert_equal true,  I18n.backend.inflector_unknown_defaults?
    assert_equal false, I18n.backend.inflector_excluded_defaults?
  end

  test "inflector store_translations: regenerates inflection structures when translations are loaded" do
    store_translations(:xx, :i18n => { :inflections => { :gender => { :o => 'other' }}})
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|o:Others|n:You|All}!')
    assert_equal 'Dear Others!',  I18n.t('hi', :gender => :o,       :locale => :xx)
    assert_equal 'Dear Lady!',    I18n.t('hi', :gender => :f,       :locale => :xx)
    assert_equal 'Dear You!',     I18n.t('hi', :gender => :unknown, :locale => :xx)
    assert_equal 'Dear All!',     I18n.t('hi', :gender => :m,       :locale => :xx)
  end

  test "inflector store_translations: raises I18n::DuplicatedInflectionToken when duplicated token is given" do
    assert_raise I18n::DuplicatedInflectionToken do
      store_translations(:xx, :i18n => { :inflections => { :gender => { :o => 'other' }, :person => { :o => 'o' }}})
    end
  end

  test "inflector store_translations: raises I18n::BadInflectionAlias when bad alias is given" do
     assert_raise I18n::BadInflectionAlias do
       store_translations(:xx, :i18n => { :inflections => { :gender => { :o => '@nonexistant' }}})
     end
     assert_raise I18n::BadInflectionAlias do
       store_translations(:xx, :i18n => { :inflections => { :gender => { :default => '@nonexistant' }}})
     end
   end

   test "inflector store_translations: raises I18n::BadInflectionToken when duplicated token is given" do
     assert_raise I18n::BadInflectionToken do
       store_translations(:xx, :i18n => { :inflections => { :gender => { :o => '@' }}})
       store_translations(:xx, :i18n => { :inflections => { :gender => { :tok => nil }}})
     end
   end

  test "inflector translate: allows pattern-only translation data" do
    store_translations(:xx, 'clear_welcome' => '@{f:Lady|m:Sir|n:You|All}')
    assert_equal 'Lady', I18n.t('clear_welcome', :gender => 'f', :locale => :xx)
  end

  test "inflector translate: allows patterns to be escaped using @@ or \\@" do
    store_translations(:xx, 'escaped_welcome' => '@@{f:AAAAA|m:BBBBB}')
    assert_equal '@{f:AAAAA|m:BBBBB}', I18n.t('escaped_welcome', :gender => 'f', :locale => :xx)
    store_translations(:xx, 'escaped_welcome' => '\@{f:AAAAA|m:BBBBB}')
    assert_equal '@{f:AAAAA|m:BBBBB}', I18n.t('escaped_welcome', :gender => 'f', :locale => :xx)
  end

  test "inflector translate: picks Lady for :f gender option" do
    assert_equal 'Dear Lady!', I18n.t('welcome', :gender => :f, :locale => :xx)
  end

  test "inflector translate: picks Lady for f gender option" do
    assert_equal 'Dear Lady!', I18n.t('welcome', :gender => 'f', :locale => :xx)
  end

  test "inflector translate: picks Sir for :m gender option"  do
    assert_equal 'Dear Sir!', I18n.t('welcome', :gender => :m, :locale => :xx)
  end

  test "inflector translate: picks Sir for :masculine gender option" do
    assert_equal 'Dear Sir!', I18n.t('welcome', :gender => :masculine, :locale => :xx)
  end

  test "inflector translate: picks Sir for masculine gender option" do
    assert_equal 'Dear Sir!', I18n.t('welcome', :gender => 'masculine', :locale => :xx)
  end

  test "inflector translate: picks an empty string when no default token is present and no free text is there" do
    store_translations(:xx, 'none_welcome' => '@{n:You|f:Lady}')
    assert_equal '', I18n.t('none_welcome', :gender => 'masculine', :locale => :xx)
  end

  test "inflector translate: allows multiple patterns in the same data" do
    store_translations(:xx, 'multiple_welcome' => '@@{f:AAAAA|m:BBBBB} @{f:Lady|m:Sir|n:You|All} @{f:Lady|All}@{m:Sir|All}@{n:You|All}')
    assert_equal '@{f:AAAAA|m:BBBBB} Sir AllSirAll', I18n.t('multiple_welcome', :gender => 'masculine', :locale => :xx)
  end

  test "inflector translate: falls back to default for the unknown gender option" do
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :unknown, :locale => :xx)
  end

  test "inflector translate: falls back to default for a gender option set to nil" do
    assert_equal 'Dear You!', I18n.t('welcome', :gender => nil, :locale => :xx)
  end

  test "inflector translate: falls back to default for no gender option" do
    assert_equal 'Dear You!', I18n.t('welcome', :locale => :xx)
  end

  test "inflector translate: falls back to free text for the proper gender option but not present in pattern" do
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s, :locale => :xx)
  end

  test "inflector translate: falls back to free text when :inflector_unknown_defaults is false" do
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :unknown,  :locale => :xx, :inflector_unknown_defaults => false)
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s,        :locale => :xx, :inflector_unknown_defaults => false)
    assert_equal 'Dear All!', I18n.t('welcome', :gender => nil,       :locale => :xx, :inflector_unknown_defaults => false)
  end

  test "inflector translate: falls back to default for no gender option when :inflector_unknown_defaults is false" do
    assert_equal 'Dear You!', I18n.t('welcome', :locale => :xx, :inflector_unknown_defaults => false)
  end

  test "inflector translate: falls back to free text for the unknown gender option when global inflector_unknown_defaults is false" do
    I18n.backend.inflector_unknown_defaults = false
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :unknown, :locale => :xx)
  end

  test "inflector translate: falls back to default for the unknown gender option when global inflector_unknown_defaults is overriden" do
    I18n.backend.inflector_unknown_defaults = false
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :unknown, :locale => :xx, :inflector_unknown_defaults => true)
  end
    
  test "inflector translate: falls back to default token for ommited gender option when :inflector_excluded_defaults is true" do
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :s, :locale => :xx, :inflector_excluded_defaults => true)
    I18n.backend.inflector_excluded_defaults = true
    assert_equal 'Dear You!', I18n.t('welcome', :gender => :s, :locale => :xx)
  end

  test "inflector translate: falls back to free text for ommited gender option when :inflector_excluded_defaults is false" do
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s, :locale => :xx, :inflector_excluded_defaults => false)
    I18n.backend.inflector_excluded_defaults = false
    assert_equal 'Dear All!', I18n.t('welcome', :gender => :s, :locale => :xx)
  end

  test "inflector translate: raises I18n::InvalidOptionForKind when bad kind is given and inflector_raises is true" do
    assert_nothing_raised I18n::InvalidOptionForKind do
      I18n.t('welcome', :locale => :xx, :inflector_raises => true)
    end
    tr = I18n.backend.send(:translations)
    tr[:xx][:i18n][:inflections][:gender].delete(:default)
    store_translations(:xx, :i18n => { :inflections => { :gender => { :o => 'other' }}})
    assert_raise(I18n::InvalidOptionForKind) { I18n.t('welcome', :locale => :xx, :inflector_raises => true) }
    assert_raise(I18n::InvalidOptionForKind) { I18n.t('welcome', :locale => :xx, :gender => "", :inflector_raises => true) }
    assert_raise(I18n::InvalidOptionForKind) { I18n.t('welcome', :locale => :xx, :gender => nil, :inflector_raises => true) }
    assert_raise I18n::InvalidOptionForKind do
     I18n.backend.inflector_raises = true
     I18n.t('welcome', :locale => :xx)
    end
  end

  test "inflector translate: raises I18n::InvalidInflectionToken when bad token is given and inflector_raises is true" do
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|o:BAD_TOKEN|n:You|First}!')
    assert_raise(I18n::InvalidInflectionToken) { I18n.t('hi', :locale => :xx, :inflector_raises => true) }
    assert_raise I18n::InvalidInflectionToken do
      I18n.backend.inflector_raises = true
      I18n.t('hi', :locale => :xx)
    end
  end

  test "inflector translate: raises I18n::MisplacedInflectionToken when bad token is given and inflector_raises is true" do
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|i:Me|n:You|First}!')
    assert_raise(I18n::MisplacedInflectionToken) { I18n.t('hi', :locale => :xx, :inflector_raises => true) }
    assert_raise I18n::MisplacedInflectionToken do
      I18n.backend.inflector_raises = true
      I18n.t('hi', :locale => :xx)
    end
  end

  test "inflector translate: works with %{} patterns" do
    store_translations(:xx, 'hi' => 'Dear @{f:Lady|m:%{test}}!')
    assert_equal 'Dear Dude!', I18n.t('hi', :gender => :m, :locale => :xx, :test => "Dude")
  end

  test "inflector translate: works with tokens separated by commas" do
    store_translations(:xx, 'hi' => 'Dear @{f,m:Someone}!')
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :m, :locale => :xx)
  end

  test "inflector translate: works with negative tokens" do
    store_translations(:xx, 'hi' => 'Dear @{!m:Lady|m:Sir|n:You|All}!')
    assert_equal 'Dear Lady!', I18n.t('hi', :gender => :n, :locale => :xx)
    assert_equal 'Dear Sir!', I18n.t('hi', :gender => :m, :locale => :xx)
    assert_equal 'Dear Lady!', I18n.t('hi', :locale => :xx)
    assert_equal 'Dear Lady!', I18n.t('hi', :gender => :unknown, :locale => :xx)
  end
  
  test "inflector translate: works with tokens separated by commas and negative tokens" do
    store_translations(:xx, 'hi' => 'Dear @{f,m:Someone}!')
    assert_equal 'Dear Someone!', I18n.t('hi', :gender => :m, :locale => :xx)
  end

  test "inflector inflected_locales: lists languages that support inflection" do
    assert_equal [:xx], I18n.backend.inflected_locales
    assert_equal [:xx], I18n.backend.inflected_locales(:gender)
  end

  test "inflector inflected_locale?: checks if a language supports inflection" do
    assert_equal true, I18n.backend.inflected_locale?(:xx)
    assert_equal false, I18n.backend.inflected_locale?(:pl)
    assert_equal false, I18n.backend.inflected_locale?(nil)
    assert_equal false, I18n.backend.inflected_locale?("")
    I18n.locale = :xx
    assert_equal true, I18n.backend.inflected_locale?
    I18n.locale = :pl
    assert_equal false, I18n.backend.inflected_locale?
    I18n.locale = nil
    assert_equal false, I18n.backend.inflected_locale?
    I18n.locale = ""
    assert_equal false, I18n.backend.inflected_locale?
  end

  test "inflector inflection_kind: checks what is the inflection kind of the given token" do
    assert_equal :gender, I18n.backend.inflection_kind(:neuter, :xx)
    assert_equal :gender, I18n.backend.inflection_kind(:f, :xx)
    assert_equal :person, I18n.backend.inflection_kind(:you, :xx)
    I18n.locale = :xx
    assert_equal :gender, I18n.backend.inflection_kind(:neuter)
    assert_equal :gender, I18n.backend.inflection_kind(:f)
    assert_equal :person, I18n.backend.inflection_kind(:you)  
    assert_equal nil, I18n.backend.inflection_kind(:faafaffafafa)
  end

  test "inflector inflection_true_token: gets true token for a given token name" do
    assert_equal :n, I18n.backend.inflection_true_token(:neuter, :xx)
    assert_equal :f, I18n.backend.inflection_true_token(:f, :xx)
    I18n.locale = :xx
    assert_equal :n, I18n.backend.inflection_true_token(:neuter)
    assert_equal :f, I18n.backend.inflection_true_token(:f)
    assert_equal nil, I18n.backend.inflection_true_token(:faafaffafafa)
  end

  test "inflector available_inflection_kinds: lists inflection kinds" do
    assert_not_nil I18n.backend.available_inflection_kinds(:xx)
    assert_equal [:gender,:person], I18n.backend.available_inflection_kinds(:xx).sort{|k,v| k.to_s<=>v.to_s}
    I18n.locale = :xx
    assert_equal [:gender,:person], I18n.backend.available_inflection_kinds.sort{|k,v| k.to_s<=>v.to_s}
  end

  test "inflector inflection_tokens: lists inflection tokens" do
    h = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange",
         :masculine=>"male",:feminine=>"female",:neuter=>"neuter",
         :neutral=>"neuter"}
    ha = h.merge(:i=>'I', :you=>'You')
    assert_equal h, I18n.backend.inflection_tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h, I18n.backend.inflection_tokens(:gender)
    assert_equal ha, I18n.backend.inflection_tokens
  end

  test "inflector inflection_true_tokens: lists true tokens" do
    h  = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange"}
    ha = h.merge(:i=>"I",:you=>"You")
    assert_equal h, I18n.backend.inflection_true_tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h, I18n.backend.inflection_true_tokens(:gender)
    assert_equal ha, I18n.backend.inflection_true_tokens
  end

  test "inflector inflection_raw_tokens: lists tokens in a so called raw format" do
    h = {:m=>"male",:f=>"female",:n=>"neuter",:s=>"strange",
         :masculine=>:m,:feminine=>:f,:neuter=>:n,
         :neutral=>:n}
    ha = h.merge(:i=>'I',:you=>"You")
    assert_equal h, I18n.backend.inflection_raw_tokens(:gender, :xx)
    I18n.locale = :xx
    assert_equal h, I18n.backend.inflection_raw_tokens(:gender)
    assert_equal ha, I18n.backend.inflection_raw_tokens    
  end

  test "inflector inflection_default_token: returns a default token for a kind" do
    assert_equal :n, I18n.backend.inflection_default_token(:gender, :xx)
    I18n.locale = :xx
    assert_equal :n, I18n.backend.inflection_default_token(:gender)
  end

  test "inflector inflection_aliases: lists aliases" do
    a = {:masculine=>:m, :feminine=>:f, :neuter=>:n, :neutral=>:n}
    assert_equal a, I18n.backend.inflection_aliases(:gender, :xx)
    I18n.locale = :xx
    assert_equal a, I18n.backend.inflection_aliases(:gender)
    assert_equal a, I18n.backend.inflection_aliases
  end

  test "inflector inflection_token_description: returns token's description" do
    assert_equal "male", I18n.backend.inflection_token_description(:m, :xx)
    I18n.locale = :xx
    assert_equal "male", I18n.backend.inflection_token_description(:m)
    assert_equal nil, I18n.backend.inflection_token_description(:nonexistent, :xx)
    assert_equal "neuter", I18n.backend.inflection_token_description(:neutral, :xx)
  end

  test "inflector inflection_is_alias?: tests whether a token is an alias" do
      assert_equal true, I18n.backend.inflection_is_alias?(:neutral, :xx)
      assert_equal false, I18n.backend.inflection_is_alias?(:you, :xx)
      I18n.locale = :xx
      assert_equal true, I18n.backend.inflection_is_alias?(:neutral)
  end
    
end
