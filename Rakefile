task :load_env do
  envs = %x[cat .env]
  envs = envs.split(/\n/)
  envs.each do |env|
    %x[export #{env}]
  end
end
