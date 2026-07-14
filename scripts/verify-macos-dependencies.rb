#!/usr/bin/env ruby

require "json"
require "open3"
require "set"

mode, lock_path = ARGV

unless %w[preflight installed].include?(mode) && lock_path
  warn "Usage: verify-macos-dependencies.rb preflight|installed dependencies.lock.json"
  exit 2
end

lock = JSON.parse(File.read(lock_path))
formulae = lock.fetch("macos").fetch("lockedFormulae")
names = formulae.keys.sort
errors = []

def capture!(*command)
  output, error, status = Open3.capture3(*command)
  raise "#{command.join(" ")} failed: #{error.strip}" unless status.success?
  output
end

if mode == "preflight"
  raw = capture!("brew", "info", "--json=v2", *names)
  available = JSON.parse(raw).fetch("formulae").to_h { |formula| [formula.fetch("name"), formula] }

  names.each do |name|
    expected = formulae.fetch(name)
    actual = available[name]
    unless actual
      errors << "#{name}: formula nao encontrada no Homebrew"
      next
    end

    actual_version = actual.dig("versions", "stable").to_s
    actual_revision = actual.fetch("revision", 0).to_i
    actual_formula_sha = actual.dig("ruby_source_checksum", "sha256").to_s

    errors << "#{name}: versao #{actual_version}, esperada #{expected.fetch("version")}" if actual_version != expected.fetch("version")
    errors << "#{name}: revisao #{actual_revision}, esperada #{expected.fetch("revision")}" if actual_revision != expected.fetch("revision").to_i
    errors << "#{name}: hash da formula foi alterado" if actual_formula_sha != expected.fetch("formulaSha256")

    actual_dependencies = actual.fetch("dependencies", []).sort
    expected_dependencies = expected.fetch("dependencies", []).sort
    errors << "#{name}: arvore direta de dependencias foi alterada" if actual_dependencies != expected_dependencies

    bottle_files = actual.dig("bottle", "stable", "files") || {}
    if bottle_files.empty?
      errors << "#{name}: nao existe bottle compativel com este Mac"
      next
    end

    bottle_files.each do |tag, bottle|
      locked_bottle = expected.fetch("bottles", {})[tag]
      if locked_bottle.nil?
        errors << "#{name}: bottle #{tag} nao foi homologado"
        next
      end
      errors << "#{name}: hash do bottle #{tag} foi alterado" if bottle.fetch("sha256", "") != locked_bottle.fetch("sha256")
      errors << "#{name}: origem do bottle #{tag} foi alterada" if bottle.fetch("url", "") != locked_bottle.fetch("url")
    end
  end
else
  installed_output = capture!("brew", "list", "--versions")
  installed = installed_output.lines.to_h do |line|
    name, *versions = line.split
    [name, versions]
  end
  pinned = capture!("brew", "list", "--pinned").lines.map(&:strip).to_set

  names.each do |name|
    expected_version = formulae.fetch(name).fetch("installedVersion")
    versions = installed.fetch(name, [])
    errors << "#{name}: versao instalada #{versions.join(", ").inspect}, esperada #{expected_version}" unless versions.include?(expected_version)
    errors << "#{name}: formula instalada, mas nao fixada com brew pin" unless pinned.include?(name)
  end
end

unless errors.empty?
  warn "JP Tools error: as dependencias homologadas do Mac nao conferem."
  errors.each { |error| warn "  - #{error}" }
  warn "  - O instalador nao usara versoes ou arquivos diferentes dos registrados em dependencies.lock.json."
  exit 1
end

message = mode == "preflight" ? "metadados e hashes" : "versoes instaladas e fixadas"
puts "JP Tools: #{formulae.length} ferramentas independentes validadas (#{message})."
