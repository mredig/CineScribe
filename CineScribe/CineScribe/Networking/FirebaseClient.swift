//
//  FirebaseClient.swift
//  CineScribe
//
//  Created by Jeffrey Santana on 9/23/19.
//  Copyright © 2019 Marlon Raskin. All rights reserved.
//  swiftlint:disable function_parameter_count

import Foundation
import Firebase

class FirebaseClient {
	
	private let rootRef = Database.database().reference()
	private let userRef: DatabaseReference
	private let reviewRef: DatabaseReference
	private let collectionRef: DatabaseReference
	var userCollections = [Collection]()
	var userReviews = [Review]()

	#warning("Remove hard-coded user")
	private var currentUser = User(username: "Santana", password: "12345", id: UUID(uuidString: "DDF188EF-D391-489B-B254-5B58629E99F6")!)
	
	init() {
		userRef = rootRef.child("users")
		reviewRef = rootRef.child("reviews")
		collectionRef = rootRef.child("collections")
	}
	
	// MARK: - Create
	
	func createUser(username: String, password: String, completion: @escaping () -> Void) {
		guard userRef.child(username).childByAutoId().key == nil else { return }
		let newUser = User(username: username, password: password)
		
		userRef.child(newUser.username).setValue(newUser.toDictionary())
		currentUser = newUser
		completion()
	}
	
	func createCollection(title: String, completion: @escaping () -> Void) {
		let newCollection = Collection(title: title)
		collectionRef.child(currentUser.id.uuidString).child(newCollection.id.uuidString).setValue(newCollection.toDictionary()) { error, _ in
			if let error = error {
				NSLog("Error creating collection: \(error)")
			} else {
				completion()
			}
		}
	}
	
	// MARK: - Read
	
	func loginUser(username: String, password: String, completion: @escaping () -> Void) {
		userRef.child(username).observeSingleEvent(of: .value) { _ in
//			let user = User(snapshot: snapshot)
//			self.currentUser = user
//			completion()
		}
	}
	
	func getAllCollections(completion: @escaping () -> Void) {
		collectionRef.child(currentUser.id.uuidString).observe(.value, with: { snapshot in
			self.userCollections.removeAll()
					   for child in snapshot.children {
						   if let snap = child as? DataSnapshot,
							   let collection = Collection(snapshot: snap) {
								   self.userCollections.append(collection)
						   }
					   }
			completion()
		}) { error in
			NSLog("Error getting collections: \(error)")
		}
	}
	
	func getReviews(completion: @escaping () -> Void) {
		reviewRef.child(currentUser.id.uuidString).observeSingleEvent(of: .value, with: { snapshot in
			self.userReviews.removeAll()
			for child in snapshot.children {
				if let snap = child as? DataSnapshot,
					let review = Review(snapshot: snap) {
					self.userReviews.append(review)
				}
			}
		}) { error in
			NSLog("Error getting collections: \(error)")
		}
	}
	
	func getReviews(from collection: Collection, completion: @escaping () -> Void) {
		let myGroup = DispatchGroup()
		
		userReviews.removeAll()
		collection.reviews.keys.forEach({
			myGroup.enter()
			reviewRef.child("\(currentUser.id.uuidString)/\($0)").observeSingleEvent(of: .value) { snapshot in
				if let review = Review(snapshot: snapshot) {
					self.userReviews.append(review)
				}
				myGroup.leave()
			}
		})

		myGroup.notify(queue: .main) {
			completion()
		}
	}
	
	// MARK: - Update
	
    func putReview(collectionId: UUID,
                   reviewId: UUID?,
                   title: String,
                   movie: Movie?,
                   memorableQuotes: String?,
                   sceneDescription: String?,
                   actorNotes: String?,
                   cinematographyNotes: String?,
                   completion: @escaping () -> Void) {
        var newReview: Review

        if let reviewId = reviewId {
            newReview = Review(title: title,
                               collectionId: collectionId,
                               movie: movie,
                               memorableQuotes: memorableQuotes,
                               sceneDescription: sceneDescription,
                               actorNotes: actorNotes,
                               cinematographyNotes: cinematographyNotes,
                               id: reviewId)
        } else {
            newReview = Review(title: title,
                               collectionId: collectionId,
                               movie: movie,
                               memorableQuotes: memorableQuotes,
                               sceneDescription: sceneDescription,
                               actorNotes: actorNotes,
                               cinematographyNotes: cinematographyNotes)
        }

        reviewRef.child("\(currentUser.id.uuidString)/\(newReview.id.uuidString)").setValue(newReview.toDictionary()) { error, _ in
            if let error = error {
                NSLog("Error creating/updating a review: \(error)")
            } else {
                self.updateCollection(for: collectionId, review: newReview)
                completion()
            }
        }
    }
	
	private func updateCollection(for collectionId: UUID, review: Review) {
		let userCollectionRef = self.collectionRef.child("\(self.currentUser.id.uuidString)/\(collectionId)")
		let collectionReviewsRef = userCollectionRef.child("reviews")
		
		userCollectionRef.child("imageUrl").setValue(review.movieImageUrl?.absoluteString) { error, _ in
			if let error = error {
				NSLog("Error adding imageUrl to collection: \(error)")
			}
		}
		collectionReviewsRef.child(review.id.uuidString).setValue(review.movieId ?? 0) { error, _ in
			if let error = error {
				NSLog("Error appending review to collection: \(error)")
			}
		}
		if let collectionIndex = self.userCollections.firstIndex(where: { $0.id == collectionId }) {
			self.userCollections[collectionIndex].reviews[collectionId.uuidString] = review.movieId ?? 0
			self.userReviews.append(review)
		}
	}
		
	// MARK: - Delete
	
	func delete(collection: Collection, completion: @escaping () -> Void) {
	collectionRef.child("\(currentUser.id.uuidString)/\(collection.id.uuidString)").removeValue()
		completion()
	}
	
	func delete(review: Review, completion: @escaping () -> Void) {
		reviewRef.child("\(currentUser.id.uuidString)/\(review.id.uuidString)").removeValue()
		completion()
	}
	
}

/*
{
	"collections": {
		"<userUUID>": {
			"<collectionUUID>": {
				"title": "<collectionName>",
				"imageUrl": "<moviePosterUrl>"
				"reviews": {
					"<reviewId>": "<movieDbId>",
					"<reviewId>": "<movieDbId>"
				}
			}
		}
	}
	"reviews": {
		"<userUUID>": {
			"<reviewId>": {
				"movieDbId": "<movieDbId>",
				"title": "Plot",
				"imageUrl": "<moviePosterUrl>"
				"collectionId": "<collectionUUID>"
			}
		}
	},
	"users": {
		"<username>": {
			"id": "<userUUID>",
			"password": "<password>"
		}
	}
}
*/
