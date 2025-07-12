# memora

## Generating `env.g.dart`
1. Create a `.env` file in the project root and define the required environment variables.
   * Refer to `.env.example` for the variables to be used.
2. Run the following command in the root directory of the `memora` project to generate the `env.g.dart` file:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## License
This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).  
See the [LICENSE](./LICENSE) file for details.
