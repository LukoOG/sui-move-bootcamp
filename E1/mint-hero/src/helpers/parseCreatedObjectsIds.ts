import { SuiObjectChange, SuiObjectChangeCreated } from "@mysten/sui/client";
import { ENV } from "../env"

interface Args {
  objectChanges: SuiObjectChange[];
}

interface Response {
  swordsIds: string[];
  heroesIds: string[];
}

const HERO_TYPE = `${ENV.PACKAGE_ID}::hero::Hero`
const SWORD_TYPE = `${ENV.PACKAGE_ID}::blacksmith::Sword`
/**
 * Parses the provided SuiObjectChange[].
 * Extracts the IDs of the created Heroes and Swords NFTs, filtering by objectType.
 */
export const parseCreatedObjectsIds = ({ objectChanges }: Args): Response => {
  // TODO: Implement this function
  
  const swordIds = objectChanges.filter((object)=>object.type ==="created" && object.objectType === HERO_TYPE ) as SuiObjectChangeCreated[]
  const heroesIds = objectChanges.filter((object)=>object.type ==="created" && object.objectType === SWORD_TYPE ) as SuiObjectChangeCreated[]
  
  return {
    swordsIds: swordIds.map(({ objectId }) => objectId),
    heroesIds: heroesIds.map(({ objectId }) => objectId),
  };
};
