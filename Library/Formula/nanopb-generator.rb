require "formula"

class NanopbGenerator < Formula
  homepage "http://koti.kapsi.fi/jpa/nanopb/docs/index.html"
  url "http://koti.kapsi.fi/~jpa/nanopb/download/nanopb-0.2.7.tar.gz"
  sha1 "7dce0b9e1f9e5d0614697a8ea1678cee76f14858"

  bottle do
    cellar :any
    sha1 "17ab08281b2734251b83a6bd771ce9f0c6472d25" => :mavericks
    sha1 "6f12390b3d7a46d43831b88b6bc5b13effc73eef" => :mountain_lion
    sha1 "68d97449f3eef3ae25fa9f063457802080bb054d" => :lion
  end

  depends_on :python if MacOS.version <= :snow_leopard
  depends_on "protobuf"

  resource "protobuf-python" do
    url "https://pypi.python.org/packages/source/p/protobuf/protobuf-2.5.0.tar.gz"
    sha1 "1a6028d113484089edbde95900b6d9467160cc41"
  end

  def install
    ENV.prepend_create_path "PYTHONPATH", libexec+"lib/python2.7/site-packages"
    resource("protobuf-python").stage do
      system "python", "setup.py", "install", "--prefix=#{libexec}"
    end

    Dir.chdir "generator"

    system "make", "-C", "proto"

    libexec.install "nanopb_generator.py", "protoc-gen-nanopb", "proto"

    (bin/"protoc-gen-nanopb").write_env_script libexec/"protoc-gen-nanopb", :PYTHONPATH => ENV["PYTHONPATH"]
    (bin/"nanopb_generator").write_env_script libexec/"nanopb_generator.py", :PYTHONPATH => ENV["PYTHONPATH"]
  end

  test do
    (testpath/"test.proto").write <<-PROTO.undent
      message Test {
        required string test_field = 1;
      }
    PROTO
    system Formula["protobuf"].bin/"protoc",
      "--proto_path=#{testpath}", "--plugin=#{bin/"protoc-gen-nanopb"}",
      "--nanopb_out=#{testpath}", testpath/"test.proto"
    system "grep", "test_field", testpath/"test.pb.c"
    system "grep", "test_field", testpath/"test.pb.h"
  end
end
