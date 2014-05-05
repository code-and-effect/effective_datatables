namespace :effective_datatables do
  desc 'Create nondigest versions of some effective_datatables assets'
  task :create_nondigest_assets do
    fingerprint = /\-[0-9a-f]{32}\./
    for file in Dir['public/assets/dataTables/*.*', 'public/assets/effective_datatables/*.*']
      next unless file =~ fingerprint
      nondigest = file.sub fingerprint, '.' # contents-0d8ffa186a00f5063461bc0ba0d96087.css => contents.css
      FileUtils.mv file, nondigest, verbose: true
    end
  end
end

# auto run ckeditor:create_nondigest_assets after assets:precompile
Rake::Task['assets:precompile'].enhance do
  puts 'undigesting required effective_datatables assets'
  Rake::Task['effective_datatables:create_nondigest_assets'].invoke
end
