use dep::std::ecdsa_secp256k1::verify_signature;
use dep::std;
use dep::std::scalar_mul;
use dep::std::hash;
use dep::ecrecover;

fn main(
  pub_key_x: [u8; 32],
  pub_key_y: [u8; 32],
  signature: [u8; 64],
  hashed_message: pub [u8; 32],
  root: pub Field,
  index: Field,
  hash_path: [Field; 2]
) {
    // First, let's check if signature is vaild and corresponds to the public key provided
    let valid_signature = verify_signature(pub_key_x, pub_key_y, signature, hashed_message);
    assert(valid_signature);

    // Grab the ethereum address from the public key
    let key = ecrecover::secp256k1::PubKey::from_xy(pub_key_x, pub_key_y);
    let leaf = key.to_eth_address();

    // Check if the address is part of the merkle tree
    let computedRoot = std::merkle::compute_merkle_root(leaf, index, hash_path);

    assert (root == computedRoot);
}