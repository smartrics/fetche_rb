require 'json'

class Deployment
  def initialize json_string
    p = JSON::Parser.new(json_string)
    @deployment = p.parse
  end

  def environments values = {}
    envs = {}
    @deployment.keys.each do | e |
      if allow?(values['env'], e)
        envs[e] = @deployment[e].keys
      end
    end
    envs
  end

  def localities values = {}
    localities = {}
    environments(values).keys.each do | e |
      @deployment[e].keys.each do | l |
        if allow?(values['loc'], l)
          localities[l] = [] if localities[l].nil?
          f = {}
          f['env'] = e
          f['comp'] = @deployment[e][l].keys.dup
          localities[l] << f
        end
      end
    end
    localities
  end

  def components values = {}
    components = {}
    loc = localities(values)
    loc.keys.each do | l |
      loc[l].each do | a |
        a['comp'].each do | c |
          if allow?(values['comp'], c)
            components[c] = [] if components[c].nil?
            components[c] << { 'env' => a['env'], 'loc' => l }
          end
        end
      end
    end
    components
  end

  def hosts values = {}
    hosts = {}
    environments(values).keys.each do | e |
      @deployment[e].keys.each do | l |
        if allow?(values['loc'], l)
          @deployment[e][l].keys.each do | c |
            if allow?(values['loc'], l)
              if allow?(values['comp'], c)
                @deployment[e][l][c].each do | i |
                  if allow?(values['host'], i['host'])
                    hosts[i['host']] = [] if hosts[i['host']].nil?
                    y = i.dup
                    y['env'] = e
                    y['loc'] = l
                    y['comp'] = c
                    hosts[i['host']] << y
                  end
                end
              end
            end
          end
        end
      end
    end
    hosts
  end

  private

  def allow?(data, el)
    data == el || data.nil? || (data.kind_of?(Array) && (data.empty? || !data.find_index(el).nil?))
  end

end