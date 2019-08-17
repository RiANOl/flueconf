describe Flueconf do
  it 'can handle primitive types' do
    fluent = Flueconf.build do
      it_is_integer 1
      it_is_negtive_integer -1
      it_is_float 1.23
      it_is_negtive_float -1.23
      it_is_string 'foo'
      it_is_special_string '#{Socket.gethostname}'
      it_is_null nil
      it_is_true true
      it_is_false false
      it_is_regexp /^.*$/
      it_is_array [1, -2, 3.3, -4.4, 'bar', nil, true, false]
      it_is_empty_array []
      it_is_hash({ foo: 123, bar: 'aaa', null: nil })
      it_is_empty_hash({})
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      it_is_integer 1
      it_is_negtive_integer -1
      it_is_float 1.23
      it_is_negtive_float -1.23
      it_is_string foo
      it_is_special_string "#{Socket.gethostname}"
      it_is_null
      it_is_true true
      it_is_false false
      it_is_regexp (?-mix:^.*$)
      it_is_array 1,-2,3.3,-4.4,bar,true,false
      it_is_empty_array 
      it_is_hash foo:123,bar:aaa
      it_is_empty_hash 
    EOF
  end

  it 'can handle array object' do
    fluent = Flueconf.build do
      it_is_array_object do
        foo 'bar'
      end
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      <it_is_array_object>
        foo bar
      </it_is_array_object>
    EOF
  end

  it 'can handle empty array object' do
    fluent = Flueconf.build do
      it_is_array_object do
      end
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      <it_is_array_object>
      </it_is_array_object>
    EOF
  end

  it 'can handle object' do
    fluent = Flueconf.build do
      it_is_object 'obj' do
        foo 'bar'
      end
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      <it_is_object obj>
        foo bar
      </it_is_object>
    EOF
  end

  it 'can handle empty object' do
    fluent = Flueconf.build do
      it_is_object 'obj' do
      end
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      <it_is_object obj>
      </it_is_object>
    EOF
  end

  it 'can handle object with multiple keys' do
    fluent = Flueconf.build do
      it_is_object 'o', 'b', 'j' do
        foo 'bar'
      end
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      <it_is_object o b j>
        foo bar
      </it_is_object>
    EOF
  end

  it 'can handle nested data types' do
    fluent = Flueconf.build do
      foo 'bar'
      obj 'nested', 'obj' do
        obj 'obj', 'in', 'obj' do
          float 3.14
          arr do
            int 123
          end
          arr do
            bool true
            arr_in_arr do
              bool false
            end
          end
        end
      end
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      foo bar
      <obj nested obj>
        <obj obj in obj>
          float 3.14
          <arr>
            int 123
          </arr>
          <arr>
            bool true
            <arr_in_arr>
              bool false
            </arr_in_arr>
          </arr>
        </obj>
      </obj>
    EOF
  end

  it 'can handle multiple builds' do
    builder = Flueconf.build do
      obj do
        first 1
      end
    end

    fluent = builder.build do
      second 2
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      <obj>
        first 1
      </obj>
      second 2
    EOF
  end

  it 'can serialize with different indent' do
    fluent = Flueconf.build do
      foo 'bar'
      obj 'nested', 'obj' do
        obj 'obj', 'in', 'obj' do
          float 3.14
          arr do
            int 123
          end
          arr do
            bool true
          end
        end
      end
    end.to_fluent(indent: 4)

    expect(fluent).to eq <<~'EOF'.chomp
      foo bar
      <obj nested obj>
          <obj obj in obj>
              float 3.14
              <arr>
                  int 123
              </arr>
              <arr>
                  bool true
              </arr>
          </obj>
      </obj>
    EOF
  end

  it 'can handle method in different context' do
    def bar
      'barbar'
    end

    fluent = Flueconf.build do
      foo bar
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      foo barbar
    EOF
  end

  it 'can handle predefined types' do
    fluent = Flueconf.build do
      system do
        dir_permission '0755'
      end
      source do
        type 'forward'
        id 'in_forward'
        label '@outside'
        port 24224
      end
      source do
        type 'tail'
        id 'in_tail_httpd_access'
        path '/var/log/httpd-access.log'
        pos_file '/var/log/td-agent/httpd-access.log.pos'
        tag 'apache.access'
        parse do
          type 'apache2'
        end
      end
      filter 'fluent.**' do
        type 'record_transformer'
        record do
          level '${tag_parts[1]}'
        end
      end
      filter '**' do
        type 'record_transformer'
        record do
          hostname '#{Socket.gethostname}'
        end
      end
      match 'fluent.**' do
        type 'rewrite_tag_filter'
        rule do
          key 'message'
          pattern /.*/
          tag 'fluent'
        end
      end
      match '**' do
        type 'forward'
        server do
          host '192.0.2.1'
          weight 100
        end
        server do
          host '192.0.2.2'
          weight 50
        end
      end
      label '@outside' do
        match '**' do
          type 'forward'
          server do
            host '192.0.2.1'
            weight 100
          end
          server do
            host '192.0.2.2'
            weight 50
          end
        end
      end
    end.to_fluent

    expect(fluent).to eq <<~'EOF'.chomp
      <system>
        dir_permission 0755
      </system>
      <source>
        @type forward
        @id in_forward
        @label @outside
        port 24224
      </source>
      <source>
        @type tail
        @id in_tail_httpd_access
        path /var/log/httpd-access.log
        pos_file /var/log/td-agent/httpd-access.log.pos
        tag apache.access
        <parse>
          @type apache2
        </parse>
      </source>
      <filter fluent.**>
        @type record_transformer
        <record>
          level ${tag_parts[1]}
        </record>
      </filter>
      <filter **>
        @type record_transformer
        <record>
          hostname "#{Socket.gethostname}"
        </record>
      </filter>
      <match fluent.**>
        @type rewrite_tag_filter
        <rule>
          key message
          pattern (?-mix:.*)
          tag fluent
        </rule>
      </match>
      <match **>
        @type forward
        <server>
          host 192.0.2.1
          weight 100
        </server>
        <server>
          host 192.0.2.2
          weight 50
        </server>
      </match>
      <label @outside>
        <match **>
          @type forward
          <server>
            host 192.0.2.1
            weight 100
          </server>
          <server>
            host 192.0.2.2
            weight 50
          </server>
        </match>
      </label>
    EOF
  end
end
