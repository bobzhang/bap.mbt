///|
test "recipes are loaded from the host file system" {
  let spec = b"(parameter n 1 \"a number\")\n(option opt $n)\n"
  match @native_io.write_file("_build/recipe-native-test.scm", spec) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @native_io.write_file("_build/recipe-native-test.recipe", spec) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @recipe.load(paths=["_build"], "recipe-native-test:n=5") {
    Ok(recipe) => {
      assert_eq(recipe.args(), ["--opt=5"])
      assert_eq(recipe.prefix(), "_build")
    }
    Err(err) => fail(err.to_string())
  }
  let fs = @recipe.FileSystem::native()
  assert_true((fs.is_directory)("_build"))
  assert_true(!(fs.is_directory)("_build/recipe-native-test.scm"))
  assert_true((fs.file_exists)("_build/recipe-native-test.scm"))
  assert_true(!(fs.file_exists)("_build/no-such-file"))
  assert_true(
    @recipe.search(["_build"]).contains("_build/recipe-native-test.recipe"),
  )
  assert_true(
    @recipe.load(paths=["_build"], "no-such-recipe") is Err(NoRecipe(_)),
  )
}
