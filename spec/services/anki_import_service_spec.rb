require 'rails_helper'

RSpec.describe AnkiImportService do
  let(:user) { create(:user) }

  describe "#import!" do
    context "with invalid file" do
      it "raises error for non-existent file" do
        service = AnkiImportService.new(user, "/tmp/nonexistent.apkg")

        expect {
          service.import!
        }.to raise_error(AnkiImportService::ImportError, /File not found/)
      end

      it "raises error for non-apkg file" do
        file_path = "/tmp/test.txt"
        File.write(file_path, "test")

        service = AnkiImportService.new(user, file_path)

        expect {
          service.import!
        }.to raise_error(AnkiImportService::ImportError, /not a .apkg file/)

        File.delete(file_path)
      end
    end

    context "with valid apkg file" do
      let(:tmpdir) { Dir.mktmpdir }
      let(:apkg_path) { File.join(tmpdir, "test.apkg") }

      after do
        FileUtils.rm_rf(tmpdir)
      end

      it "creates AnkiVocab records from database" do
        create_test_apkg(apkg_path)

        service = AnkiImportService.new(user, apkg_path)

        expect {
          service.import!
        }.to change { user.anki_vocabs.count }
      end

      it "returns import statistics" do
        create_test_apkg(apkg_path)

        service = AnkiImportService.new(user, apkg_path)
        result = service.import!

        expect(result).to have_key(:imported)
        expect(result).to have_key(:updated)
        expect(result).to have_key(:skipped)
        expect(result).to have_key(:total)
      end
    end
  end

  def create_test_apkg(path)
    tmpdir = Dir.mktmpdir
    db_path = File.join(tmpdir, "collection.anki2")

    db = SQLite3::Database.new(db_path)

    db.execute <<-SQL
      CREATE TABLE col (
        id integer primary key,
        crt integer not null,
        mod integer not null,
        scm integer not null,
        ver integer not null,
        dty integer not null,
        usn integer not null,
        ls integer not null,
        conf text not null,
        models text not null,
        decks text not null,
        dconf text not null,
        tags text not null
      );
    SQL

    db.execute <<-SQL
      INSERT INTO col VALUES (
        1, 1234567890, 1234567890, 1234567890, 11, 0, 0, 0,
        '{}', '{}', '{"1": {"name": "Default"}}', '{}', ''
      );
    SQL

    db.execute <<-SQL
      CREATE TABLE notes (
        id integer primary key,
        guid text not null,
        mid integer not null,
        mod integer not null,
        usn integer not null,
        tags text not null,
        flds text not null,
        sfld integer not null,
        csum integer not null,
        flags integer not null,
        data text not null
      );
    SQL

    db.execute <<-SQL
      INSERT INTO notes VALUES (
        1, 'abc123', 1, 1234567890, 0, 'jlpt-n5',
        '日本語#{"\x1F"}にほんご#{"\x1F"}Japanese language',
        0, 12345, 0, ''
      );
    SQL

    db.execute <<-SQL
      CREATE TABLE cards (
        id integer primary key,
        nid integer not null,
        did integer not null,
        ord integer not null,
        mod integer not null,
        usn integer not null,
        type integer not null,
        queue integer not null,
        due integer not null,
        ivl integer not null,
        factor integer not null,
        reps integer not null,
        lapses integer not null,
        left integer not null,
        odue integer not null,
        odid integer not null,
        flags integer not null,
        data text not null
      );
    SQL

    db.execute <<-SQL
      INSERT INTO cards VALUES (
        1, 1, 1, 0, 1234567890, 0, 2, 2, 100, 30, 2500, 10, 0, 0, 0, 0, 0, ''
      );
    SQL

    db.close

    Zip::File.open(path, create: true) do |zipfile|
      zipfile.get_output_stream("collection.anki2") do |f|
        f.write(File.read(db_path))
      end
    end

    FileUtils.rm_rf(tmpdir)
  end
end
